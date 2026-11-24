extends Control

## Scrolling window onto the authored campaign map scene. Shows the map at 1:1,
## opens centered on the player's current position, and pans with the mouse
## wheel, trackpad, click-and-drag, touch drag, and keyboard focus.

signal node_inspected(node_id: String)

const DRAG_THRESHOLD := 12.0
const WHEEL_STEP := 90.0
const PAN_GESTURE_SCALE := 30.0
const VIEW_MARGIN := Vector2(70, 110)
const SCROLL_TIME := 0.3

var progress: CampaignProgress
var canvas: CampaignMapCanvas
var buttons: Dictionary = {}
var selected: String = ""
var scroll_offset := Vector2.ZERO
var _tween: Tween
var _pressing := false
var _dragging := false
var _press_position := Vector2.ZERO
var _press_offset := Vector2.ZERO
var _suppress_click := false
var _follow_current := true


func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(520, 400)
	canvas = load(CampaignDefinition.MAP_SCENE).instantiate()
	add_child(canvas)
	for encounter in canvas.get_encounters():
		var id: String = encounter.encounter_id
		buttons[id] = encounter
		encounter.pressed.connect(_on_encounter_pressed.bind(id))
		encounter.focus_entered.connect(_on_encounter_focused.bind(id))
	resized.connect(_on_resized)
	refresh()


func refresh() -> void:
	if canvas != null:
		canvas.apply_progress(progress, selected)


func select(id: String) -> void:
	selected = id
	node_inspected.emit(id)
	refresh()


## Centers the view on the committed encounter, else the last victory, else the Entrance.
## The view keeps following the current position through layout changes until
## the player scrolls elsewhere.
func center_on_current(animated: bool = false) -> void:
	_follow_current = true
	_scroll_to(canvas.current_center() - size * 0.5, animated)


## Scrolls just enough to bring a map point (and its pin) fully into view.
func scroll_into_view(point: Control, animated: bool = true) -> void:
	var wanted := Rect2(point.position - VIEW_MARGIN, point.size + VIEW_MARGIN * 2.0)
	if Rect2(scroll_offset, size).encloses(wanted):
		return
	_follow_current = false
	_scroll_to(point.position + point.size * 0.5 - size * 0.5, animated)


func _on_resized() -> void:
	if _follow_current:
		center_on_current(false)
	else:
		_set_offset(scroll_offset)


func _on_encounter_pressed(id: String) -> void:
	# A drag that ends over a node pans the map instead of selecting it.
	if _suppress_click:
		return
	select(id)


func _on_encounter_focused(id: String) -> void:
	# Mouse clicks focus on press; selection then waits for the release so a
	# drag starting on a node does not select it.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	scroll_into_view(buttons[id])
	select(id)


func _input(event: InputEvent) -> void:
	if canvas == null or not is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _pressing:
		var moved: Vector2 = event.position - _press_position
		if not _dragging and moved.length() > DRAG_THRESHOLD:
			_dragging = true
			_follow_current = false
			_stop_tween()
		if _dragging:
			_set_offset(_press_offset - moved)
			get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture and _contains(event.position):
		_follow_current = false
		_stop_tween()
		_set_offset(scroll_offset + event.delta * PAN_GESTURE_SCALE)
		get_viewport().set_input_as_handled()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var wheel := Vector2.ZERO
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			wheel = Vector2(0, -1)
		MOUSE_BUTTON_WHEEL_DOWN:
			wheel = Vector2(0, 1)
		MOUSE_BUTTON_WHEEL_LEFT:
			wheel = Vector2(-1, 0)
		MOUSE_BUTTON_WHEEL_RIGHT:
			wheel = Vector2(1, 0)
		MOUSE_BUTTON_LEFT:
			if event.pressed and _contains(event.position):
				_pressing = true
				_dragging = false
				_press_position = event.position
				_press_offset = scroll_offset
			elif not event.pressed:
				if _dragging:
					_suppress_click = true
					_release_click_suppression.call_deferred()
				_pressing = false
				_dragging = false
			return
		_:
			return
	if not event.pressed or not _contains(event.position):
		return
	if event.shift_pressed:
		wheel = Vector2(wheel.y, wheel.x)
	var factor := event.factor if event.factor > 0.0 else 1.0
	_follow_current = false
	_stop_tween()
	_set_offset(scroll_offset + wheel * WHEEL_STEP * factor)
	get_viewport().set_input_as_handled()


func _release_click_suppression() -> void:
	_suppress_click = false


func _contains(viewport_position: Vector2) -> bool:
	return get_global_rect().has_point(viewport_position)


func _scroll_to(target: Vector2, animated: bool) -> void:
	_stop_tween()
	target = _clamped(target)
	if animated and is_inside_tree():
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_offset, scroll_offset, target, SCROLL_TIME)
	else:
		_set_offset(target)


func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


# Clamps scrolling to the map edges; a map smaller than the view is centered.
func _clamped(offset: Vector2) -> Vector2:
	var limit := canvas.canvas_size - size
	for axis in 2:
		offset[axis] = limit[axis] * 0.5 if limit[axis] <= 0.0 else clampf(offset[axis], 0.0, limit[axis])
	return offset


func _set_offset(offset: Vector2) -> void:
	scroll_offset = _clamped(offset)
	canvas.position = -scroll_offset

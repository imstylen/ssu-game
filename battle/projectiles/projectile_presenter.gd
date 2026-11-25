class_name ProjectilePresenter
extends BattlePresenter
## Flies a projectile from each hit's source to its target and lands the event on impact.
## Consecutive hits launch a short stagger apart and fly together (a volley); any other
## event waits until every projectile in flight has landed.

const HIT_KINDS: Array[StringName] = [&"DamageApplied", &"HealingApplied", &"ShieldAbsorbed"]
const SHIELD_COLOR := Color("#8EC9F2")

var config: ProjectilePresentationConfig
var reduce_motion: bool = false
var controller: BattleController
## Returns the global Rect2 of an endpoint: {kind: "unit" | "card" | "enemy" | "player", instance_id}.
var locate: Callable

var _projectile_root: Control
var _burst_root: Control
var _in_flight: int = 0
## The flight carrying the latest ShieldAbsorbed, so the damage that got past the Shield
## lands with the same projectile: {instance_id, events: Array, landed: bool}.
var _shield_flight: Dictionary = {}

signal _all_landed


## `overlay` hosts the flying sprites ("Projectiles") and impact bursts ("ImpactBursts").
func attach_overlay(overlay: Control) -> void:
	_projectile_root = _full_rect_control("Projectiles")
	overlay.add_child(_projectile_root)
	_burst_root = _full_rect_control("ImpactBursts")
	overlay.add_child(_burst_root)


func begin_presentation(is_instant: bool) -> void:
	super.begin_presentation(is_instant)
	_shield_flight = {}


func wait_until_ready(event: BattleEvent) -> void:
	if _in_flight > 0 and not _is_hit(event) and not _rides_shield_flight(event):
		await _all_landed


func wait_until_settled() -> void:
	if _in_flight > 0:
		await _all_landed


func present_event(event: BattleEvent, default_hold: float) -> float:
	if _rides_shield_flight(event):
		if _shield_flight.landed:
			event_landed.emit(event, _style_for(event))
		else:
			_shield_flight.events.append(event)
		return 0.0
	if not _is_hit(event):
		event_landed.emit(event, null)
		return default_hold
	var style := _style_for(event)
	var flight := {"instance_id": int(event.data.get("instance_id", -1)), "events": [event], "landed": false}
	if event.kind == &"ShieldAbsorbed":
		_shield_flight = flight
	if instant or reduce_motion or style == null or style.texture == null:
		flight.landed = true
		event_landed.emit(event, style)
		if instant:
			return 0.0
		return config.reduced_motion_hit_seconds if config != null else default_hold
	var source := _source_endpoint(event)
	var target := _target_endpoint(event)
	if _same_endpoint(source, target):
		_play_self_burst(flight, style, target)
	else:
		_launch(flight, style, source, target)
	return config.volley_stagger_seconds


# ------------------------------------------------------------- classification

func _is_hit(event: BattleEvent) -> bool:
	if not event.kind in HIT_KINDS or int(event.data.get("amount", 0)) <= 0:
		return false
	var source: Variant = event.data.get("source", {})
	return source is Dictionary and not source.is_empty()


## Damage that got past a Shield travels with the projectile the Shield blocked.
func _rides_shield_flight(event: BattleEvent) -> bool:
	return event.kind == &"DamageApplied" \
		and int(event.data.get("absorbed", 0)) > 0 \
		and not _shield_flight.is_empty() \
		and int(_shield_flight.instance_id) == int(event.data.get("instance_id", -2))


func _style_for(event: BattleEvent) -> ProjectileStyle:
	if config == null:
		return null
	var session := controller.session if controller != null else null
	var definitions: Dictionary = session.known_definitions if session != null else {}
	var enemy_definition: EnemyDefinition = session.enemy.definition if session != null and session.enemy != null else null
	return config.style_for(event, definitions, enemy_definition)


func _source_endpoint(event: BattleEvent) -> Dictionary:
	var source: Dictionary = event.data.source
	if str(source.get("kind", "")) == "enemy":
		return {"kind": "enemy"}
	return {"kind": str(source.kind), "instance_id": int(source.get("instance_id", -1))}


func _target_endpoint(event: BattleEvent) -> Dictionary:
	if event.kind == &"ShieldAbsorbed":
		return {"kind": "unit", "instance_id": int(event.data.get("instance_id", -1))}
	return {"kind": str(event.data.get("target", "")), "instance_id": int(event.data.get("instance_id", -1))}


func _same_endpoint(source: Dictionary, target: Dictionary) -> bool:
	if source.kind == "enemy" or target.kind == "enemy":
		return source.kind == target.kind
	if target.kind != "unit":
		return false
	return int(source.get("instance_id", -1)) == int(target.get("instance_id", -2))


func _rect_of(endpoint: Dictionary) -> Rect2:
	return locate.call(endpoint) if locate.is_valid() else Rect2()


# ------------------------------------------------------------------ animation

func _launch(flight: Dictionary, style: ProjectileStyle, source: Dictionary, target: Dictionary) -> void:
	var from := _rect_of(source).get_center()
	var to := _rect_of(target).get_center()
	var sprite := TextureRect.new()
	sprite.texture = style.texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.size = Vector2(style.size, style.size)
	sprite.pivot_offset = sprite.size * 0.5
	_projectile_root.add_child(sprite)
	_in_flight += 1
	var control_point := (from + to) * 0.5 + Vector2(0.0, -style.arc_height)
	var move := func(t: float) -> void:
		var point := from.lerp(control_point, t).lerp(control_point.lerp(to, t), t)
		sprite.position = point - sprite.pivot_offset
		if style.face_heading:
			var heading := (control_point - from).lerp(to - control_point, t)
			if heading.length_squared() > 0.0:
				sprite.rotation = heading.angle()
		else:
			sprite.rotation = t * style.flight_seconds * style.spin_turns_per_second * TAU
	move.call(0.0)
	var tween := sprite.create_tween()
	tween.tween_method(move, 0.0, 1.0, style.flight_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		sprite.queue_free()
		_land(flight, style, to)
	)


func _play_self_burst(flight: Dictionary, style: ProjectileStyle, target: Dictionary) -> void:
	_in_flight += 1
	var at := _rect_of(target).get_center()
	_spawn_burst(at, style.impact_color, config.self_burst_seconds)
	# Timed on the presenter, not the burst, so freeing the burst can never skip the landing.
	var tween := create_tween()
	tween.tween_interval(config.self_burst_seconds)
	tween.tween_callback(func() -> void: _land(flight, style, Vector2.INF, false))


func _land(flight: Dictionary, style: ProjectileStyle, at: Vector2, burst := true) -> void:
	flight.landed = true
	if burst and at != Vector2.INF:
		var blocked: bool = flight.events[0].kind == &"ShieldAbsorbed"
		_spawn_burst(at, SHIELD_COLOR if blocked else style.impact_color, 0.3)
		if blocked:
			_spawn_blocked_label(at, int(flight.events[0].data.get("amount", 0)))
	for event in flight.events:
		event_landed.emit(event, style)
	_in_flight -= 1
	if _in_flight == 0:
		_all_landed.emit()


func _spawn_burst(at: Vector2, color: Color, seconds: float) -> void:
	var burst := ImpactBurst.new()
	burst.color = color
	burst.position = at
	_burst_root.add_child(burst)
	var tween := burst.create_tween()
	tween.tween_property(burst, "progress", 1.0, maxf(seconds, 0.05))
	tween.tween_callback(burst.queue_free)


func _spawn_blocked_label(at: Vector2, amount: int) -> void:
	var label := Label.new()
	label.text = "Blocked %d" % amount
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", AppTheme.FREDOKA)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color("#2F6E9E"))
	label.add_theme_color_override("font_outline_color", AppTheme.SURFACE)
	label.add_theme_constant_override("outline_size", 8)
	_burst_root.add_child(label)
	label.position = at - label.get_combined_minimum_size() * 0.5 - Vector2(0.0, 36.0)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.35)
	tween.chain().tween_callback(label.queue_free)


static func _full_rect_control(node_name: String) -> Control:
	var control := Control.new()
	control.name = node_name
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return control


## An expanding, fading ring drawn around its position.
class ImpactBurst:
	extends Control

	var color := Color.WHITE
	var progress: float = 0.0:
		set(value):
			progress = value
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var faded := Color(color, 1.0 - progress)
		draw_circle(Vector2.ZERO, lerpf(10.0, 46.0, progress), Color(faded, faded.a * 0.35))
		draw_arc(Vector2.ZERO, lerpf(14.0, 58.0, progress), 0.0, TAU, 32, faded, lerpf(8.0, 2.0, progress), true)

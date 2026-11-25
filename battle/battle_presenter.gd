class_name BattlePresenter
extends Node
## Paces how BattleController presents resolved events. The base presenter shows every
## event as soon as it is presented; subclasses can hold events back until animations
## (such as projectiles) land. Rules never depend on a presenter.

## Emitted when an event's effect should become visible. `style` is the projectile
## style that delivered it, or null for events that were not delivered by a projectile.
signal event_landed(event: BattleEvent, style: ProjectileStyle)

## True while presenting with no delays (presentation_delay == 0): everything lands at once.
var instant: bool = true


func begin_presentation(is_instant: bool) -> void:
	instant = is_instant


## Suspends until `event` may be presented. Returns immediately when nothing is pending.
func wait_until_ready(_event: BattleEvent) -> void:
	pass


## Presents one event and returns the seconds to hold before the next one.
func present_event(event: BattleEvent, default_hold: float) -> float:
	event_landed.emit(event, null)
	return default_hold


## Suspends until everything already presented has landed.
func wait_until_settled() -> void:
	pass

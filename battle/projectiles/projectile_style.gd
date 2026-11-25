class_name ProjectileStyle
extends Resource
## How one kind of projectile looks and moves between an attacker and its target.
## Presentation only: rules never read these values.

@export var texture: Texture2D
## Seconds from launch to impact, whatever the distance, so pacing stays steady.
@export_range(0.05, 2.0, 0.01) var flight_seconds: float = 0.4
## Peak height of the flight arc in pixels; 0 flies straight.
@export_range(0.0, 400.0, 1.0) var arc_height: float = 60.0
## Turns per second while flying. Ignored when the sprite faces its heading.
@export_range(-10.0, 10.0, 0.1) var spin_turns_per_second: float = 1.5
## Rotate the sprite to face its flight path (art should point toward +X).
@export var face_heading: bool = false
## On-screen size of the sprite's longest side, in pixels.
@export_range(8.0, 256.0, 1.0) var size: float = 56.0
## Colour of the target flash and burst on impact.
@export var impact_color: Color = Color("#F4B942")

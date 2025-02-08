@tool
@icon("res://addons/note/texture/icon/base_texture.svg")
extends Resource
class_name BaseCuteTexture2D

enum MotionType {
	None,
	Sway,
	Breath,
	Hop,
	HumanWalk,
	LeanIn,
	LeanOut,
	Wiggle
}
enum EventType {
	None,
	Hurt,
}

@export_group("Base Settings")
@export var offset: Vector2
@export var priority: int
@export var auto_flip: bool
@export var idle_motion: MotionType
@export var moving_motion: MotionType

func get_appropriate_texture(_direction_degrees: float) -> Texture2D:
	push_error("get_appropriate_texture was not overridden for" + resource_name)
	return null

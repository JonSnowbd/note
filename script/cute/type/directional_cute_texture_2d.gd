@tool
@icon("res://addons/note/texture/icon/directional_texture.svg")
extends BaseCuteTexture2D
class_name DirectionalCuteTexture2D

@export_group("Directions")
@export var up: Texture2D
@export var right: Texture2D
@export var down: Texture2D

func get_appropriate_texture(direction_degrees: float) -> Texture2D:
	var clean_degrees = wrapf(direction_degrees+45.0, 0.0, 360.0)
	var magic = int(floor(clean_degrees/90.0)*90.0)
	
	match magic:
		0:
			return right
		90:
			return down
		180:
			return right
		270:
			return up
		360: 
			return right
	
	return null

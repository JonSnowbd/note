@tool
@icon("res://addons/note/texture/icon/simple_texture.svg")
extends BaseCuteTexture2D
class_name SimpleCuteTexture2D

@export_group("Simple Settings")
@export var texture: Texture2D

func get_appropriate_texture(_direction_degrees: float) -> Texture2D:
	return texture

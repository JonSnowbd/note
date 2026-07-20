@tool
extends Node2D
class_name SimpleParallax2D

const MetaTag = "__note_simple_parallax_meta_id"

## An extremely simple parallax alternative, you just define an anchor(the level)
## and a view node(the camera) and then set your parallax and offset, and youre set.
## Visible in editor for fast previewing

@export var view_node: Node2D
@export var view_offset: Vector2
@export var anchor_node: Node2D
@export var parallax: float = 0.0

func _process(delta: float) -> void:
	if visible and view_node != null and anchor_node != null:
		var view_position: Vector2
		if view_node is Camera2D:
			view_position = view_node.get_screen_center_position() + view_offset
		else:
			view_position = view_node.global_position + view_offset
		var offset = view_position - anchor_node.global_position
		global_position = anchor_node.global_position + (offset * parallax)

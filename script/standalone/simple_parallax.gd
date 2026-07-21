@tool
extends Node2D
class_name SimpleParallax2D

## An extremely simple parallax alternative, you just define an anchor(the level)
## and a view node(the camera) and then set your parallax and offset, and youre set.
## Visible in editor for fast previewing

## Typically this is the camera
@export var view_node: Node2D
## This is applied as a flat offset view nodes position. Treats view node as if it
## was positioned at [code]view_node.global_position+view_offset[/code]
@export var view_offset: Vector2
## Typically this is your level's root, or its terrain/tilemap node.
@export var anchor_node: Node2D
## -1.0 to 1.0, with negatives being foreground, and positive being background.
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

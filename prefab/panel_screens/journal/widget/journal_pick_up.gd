@tool
extends Control

var script_target: String

func _get_drag_data(at_position: Vector2) -> Variant:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(16,16)
	set_drag_preview(panel)
	return script_target

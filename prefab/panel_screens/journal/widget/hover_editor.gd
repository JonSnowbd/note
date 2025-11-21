@tool
extends Control

signal hovered

var cooldown: float = -1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if cooldown >= 0.0:
		cooldown -= delta

func _gui_input(event: InputEvent) -> void:
	if is_part_of_edited_scene(): return
	if cooldown > 0.0: return
	if event is InputEventMouseMotion:
		cooldown = 0.5
		hovered.emit()
		accept_event()

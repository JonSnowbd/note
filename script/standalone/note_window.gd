extends Control
class_name NoteWindow

signal closed

## Optional, automatically wires up a pressed signal to close
## window.
@export var close_button: Button
## If assigned, note.focus is begun on this if in gamepad mode.
@export var auto_focus_for_gamepad: Control
## If assigned, note.focus is begun on this if in mkb mode.
@export var auto_focus_for_mkb: Control

func _ready() -> void:
	if note.controls.is_gamepad() and auto_focus_for_gamepad != null:
		note.focus.activate(auto_focus_for_gamepad)
	if note.controls.is_mouse_and_keyboard() and auto_focus_for_mkb != null:
		note.focus.activate(auto_focus_for_mkb)
func close_window():
	closed.emit()

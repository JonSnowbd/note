extends Control

signal clicked

func _gui_input(event: InputEvent) -> void:
	if event is  InputEventMouseButton:
		if event.pressed:
			clicked.emit()

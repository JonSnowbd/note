extends FocusEffect
class_name UseButtonFocusEffect

signal pressed

func focus_confirm(down: bool, long: bool = false) -> bool:
	var parent = get_parent()
	if parent is CheckBox or parent is CheckButton:
		if down and !parent.disabled:
			parent.button_pressed = !parent.button_pressed
			#parent.toggled.emit(parent.button_pressed)
			parent.pressed.emit()
			pressed.emit()
	elif parent is Button:
		if down and !parent.disabled:
			parent.pressed.emit()
			pressed.emit()
			return true
	return false

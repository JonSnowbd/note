extends FocusEffect
class_name UseButtonFocusEffect

func focus_confirm(down: bool, long: bool = false) -> bool:
	var parent = get_parent()
	if parent is Button:
		if down and !parent.disabled:
			parent.pressed.emit()
			return true
	return false

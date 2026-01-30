extends FocusEffect
class_name PerFrameFocusEffect

@export var include_mouse_over:bool = false

signal on_process

func is_mouse_over() -> bool:
	var control = get_parent() as Control
	if control != null:
		var lmp = control.get_local_mouse_position()
		var rect = Rect2(Vector2.ZERO, control.size)
		return rect.has_point(lmp)
	return false

var active: bool = false
## VIRTUAL: Called when the parent control is focused.
func focus_enter():
	active = true
## VIRTUAL: Called when the parent control is no longer focused.
func focus_exit():
	active = false

func _process(delta: float) -> void:
	if include_mouse_over:
		if active or is_mouse_over():
			on_process.emit()
	else:
		if active:
			on_process.emit()

extends FocusEffect
class_name TemporaryDrillFocusEffect

@export var inner_focus: Control
@export var on_confirm: bool = true
@export var on_horizontal_butt: bool = false
@export var on_vertical_butt: bool = false

## VIRTUAL: Called when confirm(cross/a) is pressed/released or long pressed(if enabled).
## Return true if you consume the input.
func focus_confirm(down: bool, long: bool = false) -> bool:
	if down and !is_in_stack():
		move_to_stack()
		manager._change(inner_focus)
		return true
	return false

func focus_butted(impulse: Vector2) -> bool:
	if ((impulse.x != 0 and on_horizontal_butt) or (impulse.y != 0 and on_vertical_butt)) and !is_in_stack():
		move_to_stack()
		manager._change(inner_focus)
		return true
	return false

## VIRTUAL: Called when cancel(circle/b) is pressed/released or long pressed(if enabled).
## Return true if you consume the input.
func focus_cancel(down: bool, long: bool = false) -> bool:
	if down and is_in_stack():
		manager._change(get_parent())
		leave_stack()
		return true
	return false

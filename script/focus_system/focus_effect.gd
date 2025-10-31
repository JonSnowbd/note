@icon("res://addons/note/texture/icon/focus_effect.svg")
extends Node
class_name FocusEffect

const ManagerType = preload("uid://4iwdim3cbvkf")
const MetaTag = "__note_focus_effect_exists"

@onready var manager: ManagerType = get_tree().root.get_node("note").focus
var has_long_press: bool = false

func _enter_tree() -> void:
	get_parent().set_meta(MetaTag, true)
func move_to_stack():
	if !manager._stacked_effects.has(self):
		manager._stacked_effects.append(self)
	manager._loaded_effects.erase(self)
func leave_stack():
	manager._stacked_effects.erase(self)
	if manager.target == get_parent() and !manager._loaded_effects.has(self):
		manager._loaded_effects.append(self)
func is_in_stack() -> bool:
	return manager._stacked_effects.has(self)

## VIRTUAL: Called when a deeper child is focused. Use this for effects you want active while
## focus is inside this area. For example l1/r1 bumpers to swap tabs on a panel.
func focus_acknowledge():
	pass
## VIRTUAL: Called when the parent control is focused.
func focus_enter():
	pass
## VIRTUAL: Called when the parent control is no longer focused.
func focus_exit():
	pass
## VIRTUAL: Do drawing in here if you need.
func focus_draw(source: Control):
	pass
## VIRTUAL: Called when confirm(cross/a) is pressed/released or long pressed(if enabled).
## Return true if you consume the input.
func focus_confirm(down: bool, long: bool = false) -> bool:
	return false
## VIRTUAL: Called when cancel(circle/b) is pressed/released or long pressed(if enabled).
## Return true if you consume the input.
func focus_cancel(down: bool, long: bool = false) -> bool:
	return false
## VIRTUAL: Called when special1(square/x) is pressed/released or long pressed(if enabled).
## Return true if you consume the input.
func focus_special1(down: bool, long: bool = false) -> bool:
	return false
## VIRTUAL: Called when special2(triangle/y) is pressed/released or long pressed(if enabled).
## Return true if you consume the input.
func focus_special2(down: bool, long: bool = false) -> bool:
	return false
## VIRTUAL: Called when the direction change(dpad, left stick) cannot find a 
## neighbour, and instead forwards the input here. Useful for slider
## interactions (left input decrease, right input increase etc)
func focus_butted(impulse: Vector2) -> bool:
	return false

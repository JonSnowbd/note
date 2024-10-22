extends Node
class_name NoteGamepadControlHandler

const MetaTag_ID = "NoteGamepadControlHandler"
var manager: NoteGamepadControlManager

static func sort_fn(lhs: NoteGamepadControlEffect, rhs: NoteGamepadControlEffect)-> bool:
	return lhs.priority < rhs.priority

## Higher = ran first
@export var priority: int = 0

func _ready() -> void:
	var parent = get_parent()
	if parent is not Control:
		push_error("Control handlers go as children of a control")
	if parent.has_meta(MetaTag_ID):
		var arr: Array = parent.get_meta(MetaTag_ID)
		arr.append(self)
		arr.sort_custom(sort_fn)
	else:
		parent.set_meta(MetaTag_ID, [self])


## Virtual. Do your input stuff here. For good compatibility refer to context for
## action strings. Return true if the handler consumed the input.
func handler_input(context: NoteGamepadControlManager, event: InputEvent) -> bool:
	return false
## Virtual, when the gamepad hovers this control, this is ran
func handler_left():
	pass
## Virtual, when the gamepad leaves this control, this is ran
func handler_entered():
	pass

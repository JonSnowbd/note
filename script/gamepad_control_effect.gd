extends Node
class_name NoteGamepadControlEffect

const MetaTag_ID = "NoteGamepadControlEffect"

@export var priority: int = 0

static func sort_fn(lhs: NoteGamepadControlEffect, rhs: NoteGamepadControlEffect)-> bool:
	return lhs.priority < rhs.priority

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	var parent = get_parent()
	if parent.has_meta(MetaTag_ID):
		var arr: Array = parent.get_meta(MetaTag_ID)
		arr.append(self)
		arr.sort_custom(sort_fn)
	else:
		parent.set_meta(MetaTag_ID, [self])


## Virtual, called when the node is no longer selected
func effect_start():
	pass
## Virtual, called when the node is no longer selected
func effect_end():
	pass
## Virtual, called on _process
func effect_process(delta: float):
	pass
## Virtual, if you need to draw each frame, this is done
## centered on the control.
func effect_draw(source: Node2D, context: Control):
	pass

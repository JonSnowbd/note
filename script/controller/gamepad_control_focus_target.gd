extends Node
class_name NoteGamepadControlFocusTarget

const MetaTag_ID = "NoteGamepadControlFocusTargetTag"
const Group_ID = "NoteGamepadControlFocus"

static func get_focus_target(child: Control) -> NoteGamepadControlFocusTarget:
	var parent = child.get_parent()
	while parent != null:
		if parent.has_meta(MetaTag_ID):
			return parent.get_meta(MetaTag_ID)
		parent = parent.get_parent()
	return null

static func get_possible_targets_in_scene() -> Array[NoteGamepadControlFocusTarget]:
	var arr: Array[NoteGamepadControlFocusTarget] = []
	var hits = note.get_tree().get_nodes_in_group(Group_ID)
	for h in hits:
		if h is NoteGamepadControlFocusTarget and h.active:
			arr.append(h)
	return arr

func _enter_tree() -> void:
	add_to_group(Group_ID)

@export var active: bool
@export var priority: int = 0
@export var entry_control: Control

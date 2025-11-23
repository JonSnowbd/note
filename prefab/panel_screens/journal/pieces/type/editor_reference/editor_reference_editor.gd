@tool
extends Control

const RefType = preload("uid://ctaymxqonp17p")

@export var current_path_label: Label
@export var description_editor: CodeEdit
@export var drop_target: Control
@export var color_edit: ColorPickerButton

var current_target: RefType

func begin(target: RefType):
	if is_part_of_edited_scene(): return
	current_path_label.text = target.make_real_name(target.path)
	current_target = target
	description_editor.text = target.description
	color_edit.color = target.color
	description_editor.text_changed.connect(forward_desc_changes.bind(target))
	color_edit.color_changed.connect(target.reference_set_color)
	drop_target.set_drag_forwarding(_forwarded_get_drag, _forwarded_can_drop, _forwarded_drop)

func forward_desc_changes(to: RefType):
	to.reference_set_description(description_editor.text)

func _forwarded_get_drag(at: Vector2) -> Variant:
	return null
func _forwarded_can_drop(at: Vector2, data) -> bool:
	if data is Dictionary:
		if data["type"] == "files":
			return true
	return false
func _forwarded_drop(at: Vector2, data):
	if data is Dictionary:
		if data["type"] == "files":
			var uid = ResourceUID.path_to_uid(data["files"][0])
			if current_target != null:
				current_target.reference_set_path(uid)
			current_path_label.text = current_target.make_real_name(uid)

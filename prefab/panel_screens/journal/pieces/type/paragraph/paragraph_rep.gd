@tool
extends MarginContainer

const ParagraphType = preload("uid://btvdvje538ery")

@export var label: RichTextLabel
@export var margin: MarginContainer
@export var color_pick: ColorPickerButton

func begin(target: ParagraphType):
	if is_part_of_edited_scene(): return
	update_to_spec(target)
	target.changed.connect(update_to_spec.bind(target))
func update_to_spec(target: ParagraphType):
	label.text = target.text
	margin.add_theme_constant_override("margin_left", int(target.inset))
	label.modulate = target.color

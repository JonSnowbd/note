@tool
extends Control

const ParagraphType = preload("uid://btvdvje538ery")

@export var editor: CodeEdit
@export var inset_slider: SpinBox
@export var color_edit: ColorPickerButton

func begin(target: ParagraphType):
	if is_part_of_edited_scene(): return
	editor.text = target.text
	inset_slider.value = target.inset
	color_edit.color = target.color
	editor.text_changed.connect(forward_changes.bind(target))
	inset_slider.value_changed.connect(target.paragraph_set_inset)
	color_edit.color_changed.connect(target.paragraph_set_color)

func forward_changes(to: ParagraphType):
	to.paragraph_set_text(editor.text)

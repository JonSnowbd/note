@tool
extends Control

const TitleType = preload("uid://tkfiwacw0387")

@export var title_editor: LineEdit
@export var color_editor: ColorPickerButton
@export var size_editor: SpinBox

func begin(title:TitleType):
	title_editor.text = title.text
	color_editor.color = title.color
	size_editor.value = title.size
	
	title_editor.text_changed.connect(title.title_set_text)
	color_editor.color_changed.connect(title.title_set_color)
	size_editor.value_changed.connect(title.title_set_size)

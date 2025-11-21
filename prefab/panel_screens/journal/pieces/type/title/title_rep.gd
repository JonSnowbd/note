@tool
extends Control

const TitleType = preload("uid://tkfiwacw0387")

@export var title_label: Label

func begin(title:TitleType):
	title_label.label_settings = LabelSettings.new()
	update_to(title)
	title.changed.connect(update_to.bind(title))
func update_to(title:TitleType):
	title_label.modulate = title.color
	title_label.text = title.text
	title_label.label_settings.font_size = int(title.size)

extends Container

@export var title: Label
@export var body: RichTextLabel

func tooltip(data: Array):
	var width = ProjectSettings.get_setting("display/window/size/viewport_width", 1280) / 3.5
	custom_minimum_size = Vector2(min(width, 410.0), 0.0)
	if data[0] == "":
		title.hide()
	else:
		title.text = data[0]
	if data[1] == "":
		body.hide()
	else:
		body.text = data[1]

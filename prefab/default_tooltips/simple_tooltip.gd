extends Container

@export var body: RichTextLabel

func tooltip(data: String):
	var width = ProjectSettings.get_setting("display/window/size/viewport_width", 1280) / 3.5
	custom_minimum_size = Vector2(min(width, 410.0), 0.0)
	body.text = data

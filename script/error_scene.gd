extends Node
class_name NoteErrorScene
@export var title_label: Label
@export var description_label: Label
@export var context_label: Label


func set_error(title: String, description: String, data):
	title_label.text = title
	title_label.show()
	description_label.text = description
	description_label.show()
	context_label.visible = data != null
	if data != null:
		if data is Dictionary:
			context_label.text = JSON.stringify(data)
			return
		if data is String:
			context_label.text = data
			return
		if data is Node:
			var desc = data.name+"\n"
			desc += "#"+str(data.get_instance_id())+"\n"
			context_label.text = desc
			return
		context_label.hide()

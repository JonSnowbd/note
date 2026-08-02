extends Node
class_name NotePreloader

@export_file var files: Array[String]

func _ready() -> void:
	for f in files:
		note.loading.prewarm(f)

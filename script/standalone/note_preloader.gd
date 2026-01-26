extends Node
class_name NotePreloader

@export_file var files: Array[String]

func _ready() -> void:
	for f in files:
		if !note.loading_screen.is_cached(f):
			note.loading_screen.shadow_load(f)

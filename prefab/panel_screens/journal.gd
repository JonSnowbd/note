@tool
extends Control


@export var journal_path: String = "res://addons/note/_journal.tres"
var journal: JournalResource


func _ready() -> void:
	if FileAccess.file_exists(journal_path):
		journal = ResourceLoader.load(journal_path)
	else:
		journal = JournalResource.new()
		_save()

func _save():
	if journal != null:
		ResourceSaver.save(journal, journal_path)

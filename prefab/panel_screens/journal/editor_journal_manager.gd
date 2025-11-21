@tool
extends Control

@export var viewer: NoteJournalViewer
const path: String = "res://addons/note/_journal.tres"

var journal: NoteJournalResource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if FileAccess.file_exists(path):
		journal = load(path) as NoteJournalResource
	else:
		journal = NoteJournalResource.new()
		journal.resource_path = path
		journal.create_new_document("New Document")
		save()
	viewer.set_journal(journal)
	viewer.should_save.connect(save)

func save():
	ResourceSaver.save(journal)

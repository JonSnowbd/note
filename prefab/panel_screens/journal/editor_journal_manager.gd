@tool
extends Control

@export var viewer: NoteJournalViewer
const path: String = "res://addons/note/_journal.tres"

var journal: NoteJournalResource
var is_in_settings_file: bool = false
var settings: NoteDeveloperSettings

func load_journal_through_note():
	if settings == null:
		print("Temp journal created as no note settings are found.")
		load_journal_through_temp()
		return
	if settings.developer_journal == null:
		if FileAccess.file_exists(path):
			print("Migrating Journal from temp path %s to Note Settings" % path)
			var old_journal = load(path) as NoteJournalResource
			if old_journal != null:
				settings.developer_journal = old_journal.duplicate(true)
				journal = settings.developer_journal
				print("Success. Note Settings now contains the journal.")
			else:
				print("Failed to load journal via temp.")
				load_journal_through_temp()
				return
		else:
			
			settings.developer_journal = NoteJournalResource.new()
			settings.developer_journal.create_new_document("New Document")
			print("Created new Journal blank in the Note Settings directly.")
	else:
		journal = settings.developer_journal
	is_in_settings_file = true
	
func load_journal_through_temp():
	if FileAccess.file_exists(path):
		journal = load(path) as NoteJournalResource
	else:
		journal = NoteJournalResource.new()
		journal.resource_path = path
		journal.create_new_document("New Document")
		save()
	print("Loading Journal via temp path: %s" % path)
	is_in_settings_file = false
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_part_of_edited_scene(): return
	
	var settings_path: String = ProjectSettings.get_setting("addons/note/settings", "")
	settings = load(ProjectSettings.get_setting("addons/note/settings", "")) as NoteDeveloperSettings
	if settings == null:
		load_journal_through_temp()
	else:
		load_journal_through_note()
	
	viewer.set_journal(journal)
	viewer.should_save.connect(save)

func save():
	if is_part_of_edited_scene(): return
	if is_in_settings_file:
		ResourceSaver.save(settings)
	else:
		ResourceSaver.save(journal)

@tool
extends NoteJournalResource.Piece

var path: String
var description: String
var color: Color

var cached_scene = null

func _serialize() -> Dictionary:
	return {
		"_uuid" = uuid,
		"_script" = "uid://ctaymxqonp17p",
		"title" = title,
		"color" = color.to_html(),
		"path" = path,
		"description" = description
	}
func _first_time_setup():
	title = ""
	path = ""
	description = tr("A reference to a file.")
	color = Color.WHITE
func _deserialize(data: Dictionary):
	uuid = data["_uuid"]
	title = data.get_or_add("title", tr("New Paragraph"))
	color = Color.from_string(data.get_or_add("color", "#FFFFFFFF"), Color.WHITE)
	path = data.get_or_add("path", "")
	description = data.get_or_add("description", tr("A reference to a file."))
	cached_scene = null
	if FileAccess.file_exists(path):
		cached_scene = load(path)
func _make_entry() -> NoteJournalResource.PickUpType:
	var inst = preload("uid://c52vtg71sbmwg").instantiate() as NoteJournalResource.PickUpType
	inst.label.text = tr("Editor Reference")
	inst.script_target = "uid://btvdvje538ery"
	return inst
func _make_rep() -> Control:
	var rep = preload("uid://c303j7d7piu4f").instantiate()
	rep.begin(self)
	return rep
func _make_editor() -> Control:
	var rep = preload("uid://fbcnqfoikgkv").instantiate()
	rep.begin(self)
	return rep

func reference_set_path(new_path: String):
	path = new_path
	if FileAccess.file_exists(new_path):
		cached_scene = load(new_path)
	else:
		cached_scene = null
	changed.emit()
func reference_set_description(new_description: String):
	description = new_description
	changed.emit()
func reference_set_color(new_color: Color):
	color = new_color
	changed.emit()

func make_real_name(file_path: String) -> String:
	var p = file_path
	if file_path.begins_with("uid://"):
		p = ResourceUID.uid_to_path(file_path)
	return p.split("/")[-1]
	

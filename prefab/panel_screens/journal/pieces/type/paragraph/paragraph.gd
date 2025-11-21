@tool
extends NoteJournalResource.Piece

var text: String
var inset: float
var color: Color

func _serialize() -> Dictionary:
	return {
		"_uuid" = uuid,
		"_script" = "uid://btvdvje538ery",
		"title" = title,
		"text" = text,
		"inset" = inset,
		"color" = color.to_html()
	}
func _first_time_setup():
	title = ""
	text = tr("New Paragraph")
	inset = 0.0
	color = Color.WHITE
func _deserialize(data: Dictionary):
	uuid = data["_uuid"]
	text = data.get_or_add("text", "")
	title = data.get_or_add("title", tr("New Paragraph"))
	color = Color.from_string(data.get_or_add("color", "#FFFFFFFF"), Color.WHITE)
	inset = data.get_or_add("inset", 0.0)
func _make_entry() -> NoteJournalResource.PickUpType:
	var inst = preload("uid://c52vtg71sbmwg").instantiate() as NoteJournalResource.PickUpType
	inst.label.text = tr("Paragraph")
	inst.script_target = "uid://btvdvje538ery"
	return inst
func _make_rep() -> Control:
	var rep = preload("uid://df36fneqf4q0b").instantiate()
	rep.begin(self)
	return rep
func _make_editor() -> Control:
	var rep = preload("uid://curfgujfpvfe4").instantiate()
	rep.begin(self)
	return rep

func paragraph_set_text(new_text: String):
	text = new_text
	changed.emit()
func paragraph_set_inset(new_inset: float):
	inset = new_inset
	changed.emit()
func paragraph_set_color(new_color: Color):
	color = new_color
	changed.emit()

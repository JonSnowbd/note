@tool
extends NoteJournalResource.Piece

var text: String
var size: float
var color: Color

func _serialize() -> Dictionary:
	return {
		"_uuid" = uuid,
		"_script" = "uid://tkfiwacw0387",
		"title" = title,
		"text" = text,
		"size" = size,
		"color" = color.to_html()
	}
func _first_time_setup():
	title = tr("New Title")
	text = tr("Title")
	size = 26.0
	color = Color.WHITE
func _deserialize(data: Dictionary):
	uuid = data["_uuid"]
	text = data.get_or_add("text", "")
	title = data.get_or_add("title", tr("New Title"))
	size = data.get_or_add("size", 26.0)
	color = Color.from_string(data.get_or_add("color", "#FFFFFFFF"), Color.WHITE)

func _make_entry() -> NoteJournalResource.PickUpType:
	var inst = preload("uid://c52vtg71sbmwg").instantiate() as NoteJournalResource.PickUpType
	inst.label.text = tr("Title")
	inst.script_target = "uid://tkfiwacw0387"
	return inst

func _make_rep() -> Control:
	var rep = preload("uid://c0qbuw5pkme35").instantiate()
	rep.begin(self)
	return rep
func _make_editor() -> Control:
	var rep = preload("uid://bd5y01kwbekmb").instantiate()
	rep.begin(self)
	return rep

func title_set_text(new_string: String):
	text = new_string
	changed.emit()
func title_set_size(new_size: float):
	size = new_size
	changed.emit()
func title_set_color(new_color: Color):
	color = new_color
	changed.emit()

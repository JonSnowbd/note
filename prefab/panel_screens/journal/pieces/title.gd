@tool
extends NoteJournalResource.Piece

var text: String
var label: Label
var edit: LineEdit

func _serialize() -> Dictionary:
	return {
		"_uuid" = uuid,
		"_script" = "uid://tkfiwacw0387",
		"title" = title,
		"text" = text,
	}
func _first_time_setup():
	title = tr("New Title")
	text = tr("Title")
func _deserialize(data: Dictionary):
	uuid = data["_uuid"]
	text = data.get_or_add("text", "")
	title = data.get_or_add("title", tr("New Title"))
func _make_entry() -> NoteJournalResource.PickUpType:
	var inst = preload("uid://c52vtg71sbmwg").instantiate() as NoteJournalResource.PickUpType
	inst.label.text = tr("Title")
	inst.script_target = "uid://tkfiwacw0387"
	return inst
func _make_rep() -> Control:
	label = Label.new()
	label.text = text
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 26
	return label
func _make_editor() -> Control:
	edit = LineEdit.new()
	edit.text = text
	edit.text_changed.connect(update_value)
	return edit

func update_value(new_string: String):
	text = new_string
	label.text = new_string

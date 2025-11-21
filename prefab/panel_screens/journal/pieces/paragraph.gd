@tool
extends NoteJournalResource.Piece

var text: String
var label: RichTextLabel
var edit: CodeEdit

func _serialize() -> Dictionary:
	return {
		"_uuid" = uuid,
		"_script" = "uid://btvdvje538ery",
		"title" = title,
		"text" = text,
	}
func _first_time_setup():
	title = ""
	text = tr("New Paragraph")
func _deserialize(data: Dictionary):
	uuid = data["_uuid"]
	text = data.get_or_add("text", "")
	title = data.get_or_add("title", tr("New Paragraph"))
func _make_entry() -> NoteJournalResource.PickUpType:
	var inst = preload("uid://c52vtg71sbmwg").instantiate() as NoteJournalResource.PickUpType
	inst.label.text = tr("Paragraph")
	inst.script_target = "uid://btvdvje538ery"
	return inst
func _make_rep() -> Control:
	label = RichTextLabel.new()
	label.text = text
	label.fit_content = true
	label.bbcode_enabled = true
	return label
func _make_editor() -> Control:
	edit = CodeEdit.new()
	edit.text = text
	edit.text_changed.connect(update_value)
	edit.gutters_draw_line_numbers = true
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.autowrap_mode = TextServer.AUTOWRAP_WORD
	edit.scroll_fit_content_height = true
	return edit
func _update():
	label.text = text

func update_value():
	text = edit.text
	label.text = edit.text

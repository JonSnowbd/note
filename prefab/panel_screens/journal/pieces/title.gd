@tool
extends NoteJournalResource.Piece

var text: String
var label: RichTextLabel
var edit: CodeEdit

func _serialize() -> Dictionary:
	return {
		"_uuid" = uuid,
		"_type" = "uid://btvdvje538ery",
		"title" = title,
		"text" = text,
	}
func _initial_data():
	title = tr("New Paragraph")
func _deserialize(data: Dictionary):
	uuid = data["_uuid"]
	text = data.get_or_add("text", "")
	title = data.get_or_add("title", tr("New Paragraph"))
func _make_entry() -> Button:
	var btn = Button.new()
	btn.text = tr("Paragraph")
	return btn
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
	return edit
func _update():
	label.text = text

func update_value():
	label.text = edit.text

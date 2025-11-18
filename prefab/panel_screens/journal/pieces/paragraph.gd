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
func _first_time_setup():
	title = tr("New Paragraph")
	text = tr("Double Click to Edit")
func _deserialize(data: Dictionary):
	uuid = data["_uuid"]
	text = data.get_or_add("text", "")
	title = data.get_or_add("title", tr("New Paragraph"))
func _make_entry() -> Control:
	var panel = PanelContainer.new()
	var panel_label = Label.new()
	panel_label.text = tr("Paragraph")
	panel.add_child(panel_label)
	return panel
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

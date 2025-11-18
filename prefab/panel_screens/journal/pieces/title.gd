@tool
extends NoteJournalResource.Piece

var text: String
var label: RichTextLabel
var edit: LineEdit

func _serialize() -> Dictionary:
	return {
		"_uuid" = uuid,
		"_type" = "uid://tkfiwacw0387",
		"title" = title,
		"text" = text,
	}
func _first_time_setup():
	title = tr("New Title")
	text = tr("Edit me")
func _deserialize(data: Dictionary):
	uuid = data["_uuid"]
	text = data.get_or_add("text", "")
	title = data.get_or_add("title", tr("New Title"))
func _make_entry() -> Control:
	var panel = PanelContainer.new()
	var panel_label = Label.new()
	panel_label.text = tr("Title")
	panel.add_child(panel_label)
	return panel
func _make_rep() -> Control:
	label = RichTextLabel.new()
	label.text = text
	label.fit_content = true
	label.bbcode_enabled = true
	return label
func _make_editor() -> Control:
	edit = LineEdit.new()
	edit.text = text
	edit.text_changed.connect(update_value)
	return edit

func update_value(new_string: String):
	text = new_string
	label.text = new_string

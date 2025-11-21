@tool
extends Object

signal changed

var title: String
var uuid: String
var document: NoteJournalDocument
func set_title(new_title:String):
	title = new_title
	if document._tree_item != null:
		document.update_document_title()
		document._tree_item.set_text(0, document.document_title)
	changed.emit()
func _first_time_setup():
	pass
func _serialize() -> Dictionary:
	return {}
func _deserialize(data: Dictionary):
	pass
func _make_entry() -> NoteJournalResource.PickUpType:
	return null
func _make_rep() -> Control:
	return null
func _make_editor() -> Control:
	return null
func forward_changes_to_document():
	for i in range(len(document.pieces)):
		if document.piece_data[i]["_uuid"] == uuid:
			document.piece_data[i] = _serialize()
			break

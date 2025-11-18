@tool
extends Resource
class_name NoteJournalResource

signal word_updated
signal tree_changed

@export var documents: Array[NoteJournalDocument] = []
@export var words: Dictionary[String,Variant] = {}

class Piece extends Object:
	signal changed
	var title: String
	var uuid: String
	var document: NoteJournalDocument
	func set_title(new_title:String):
		title = new_title
		changed.emit()
	func _first_time_setup():
		pass
	func _serialize() -> Dictionary:
		return {}
	func _deserialize(data: Dictionary):
		pass
	func _make_entry() -> Control:
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

func create_new_document(new_document_title: String, parent: NoteJournalDocument = null) -> NoteJournalDocument:
	var new_document = NoteJournalDocument.new()
	if parent != null:
		parent.children.append(new_document)
		new_document.parent = parent
	else:
		documents.append(new_document)
	new_document.saturate()
	emit_changed()
	tree_changed.emit()
	return null

func delete_document(document: NoteJournalDocument):
	tree_changed.emit()

func set_word(word: String, val: Variant):
	words[word] = val
	word_updated.emit()

func find_document_by_uuid(uuid: String, inside: NoteJournalDocument = null) -> NoteJournalDocument:
	if inside != null:
		for c in inside.children:
			if c.uuid == uuid:
				return c
			else:
				var found = find_document_by_uuid(uuid, c)
				if found != null:
					return found
	else:
		for doc in documents:
			if doc.uuid == uuid:
				return doc
			var found = find_document_by_uuid(uuid, doc)
			if found != null:
				return found
	return null

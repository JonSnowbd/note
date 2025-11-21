@tool
extends Resource
class_name NoteJournalResource

const PickUpType = preload("uid://cxj8y7idv21t")

signal word_updated
signal tree_changed

@export var documents: Array[NoteJournalDocument] = []
@export var words: Dictionary[String,Variant] = {}

const Piece = preload("uid://46j4id6nlbsk")

func create_new_document(new_document_title: String, parent: NoteJournalDocument = null) -> NoteJournalDocument:
	var new_document = NoteJournalDocument.new()
	new_document.create_piece(0, "res://addons/note/prefab/panel_screens/journal/pieces/title.gd")
	new_document.create_piece(1, "res://addons/note/prefab/panel_screens/journal/pieces/paragraph.gd")
	if parent != null:
		parent.children.append(new_document)
		new_document.parent = parent
	else:
		documents.append(new_document)
	new_document.saturate()
	new_document.pieces[0].title = new_document_title
	emit_changed()
	tree_changed.emit()
	return new_document

func delete_document(document: NoteJournalDocument):
	if document.parent == null:
		documents.erase(document)
	else:
		document.parent.children.erase(document)
	
	document.parent = null
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

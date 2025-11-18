@tool
extends Resource
class_name NoteJournalDocument

@export var parent: NoteJournalDocument
@export var uuid: String = ""
@export var alignment: int = 0
@export var document_title: String = "New Document"
@export var pieces: Array[Dictionary] = []
@export var children: Array[NoteJournalDocument]

func saturate():
	if uuid.is_empty():
		uuid = UUID.v4()
	for c in children:
		c.saturate()
		c.parent = self
	for p in pieces:
		if !p.has("_uuid"):
			p["_uuid"] = UUID.v4()

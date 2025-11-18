@tool
extends Resource
class_name NoteJournalDocument

signal new_piece_added(at_index: int, piece: NoteJournalResource.Piece)
signal deleted_piece(at_index: int)

@export var parent: NoteJournalDocument
@export var uuid: String = ""
@export var alignment: int = 0
@export var document_title: String = "New Document"
@export var piece_data: Array[Dictionary] = []
@export var children: Array[NoteJournalDocument]

var pieces: Array[NoteJournalResource.Piece] = []

func saturate():
	if uuid.is_empty():
		uuid = UUID.v4()
	for p in piece_data:
		if !p.has("_uuid"):
			p["_uuid"] = UUID.v4()
		var new_piece = Object.new()
		var piece_script = load(p["_script"])
		new_piece.set_script(piece_script)
		if new_piece is NoteJournalResource.Piece:
			new_piece.document = self
			new_piece._deserialize(p)
			pieces.append(new_piece)
	emit_changed()
	for c in children:
		c.saturate()
		c.parent = self

func store_data_changes():
	for p in pieces:
		p.forward_changes_to_document()

func create_piece(at: int, script: String):
	var piece = Object.new()
	var piece_script = load(script) as Script
	piece.set_script(piece_script)
	if piece is NoteJournalResource.Piece:
		piece.title = "New Piece"
		piece.uuid = UUID.v4()
		piece.document = self
		piece._first_time_setup()
		pieces.insert(at, piece)
		piece_data.insert(at, piece._serialize())
	new_piece_added.emit(at, piece)
	emit_changed()
func delete_piece(piece: NoteJournalResource.Piece):
	var deleted_uid = piece.uuid
	pieces.erase(piece)
	var index_to_delete = piece_data.find_custom(func(obj):
		return obj["_uuid"] == deleted_uid
	)
	if index_to_delete != -1:
		piece_data.remove_at(index_to_delete)
		deleted_piece.emit(index_to_delete)
	emit_changed()

func create_editor_for_piece(piece: NoteJournalResource.Piece) -> NoteJournalChunkEditor:
	const ChunkPrefab = preload("uid://ckof76baydwrj")
	var new_editor = ChunkPrefab.instantiate() as NoteJournalChunkEditor
	new_editor.set_source(piece)
	return new_editor
func create_representation_list() -> Array[NoteJournalChunkEditor]:
	var arr: Array[NoteJournalChunkEditor] = []
	for p in pieces:
		arr.append(create_editor_for_piece(p))
	return arr

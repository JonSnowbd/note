@tool
extends Resource
class_name NoteJournalDocument

signal new_piece_added(at_index: int, piece: NoteJournalResource.Piece)
signal deleted_piece(at_index: int)

var parent: NoteJournalDocument
@export var uuid: String = ""
@export var alignment: int = 0
@export var piece_data: Array[Dictionary] = []
@export var children: Array[NoteJournalDocument]

var pieces: Array[NoteJournalResource.Piece] = []
var document_title: String
var _tree_item: TreeItem

func update_document_title():
	if !pieces.is_empty():
		document_title = pieces[0].title
		if document_title.is_empty():
			document_title = tr("Unnamed Document")
	else:
		document_title = tr("New Document")

func saturate():
	if uuid.is_empty():
		uuid = UUID.v4()
	for p in piece_data:
		if !p.has("_uuid"):
			p["_uuid"] = UUID.v4()
		
		# Check if we already have the piece saturated into a type.
		var should_instance_as_script: bool = true
		for real_piece in pieces:
			if real_piece.uuid == p["_uuid"]:
				should_instance_as_script = false
				break
		if !should_instance_as_script:
			continue
		
		# If not, we can go ahead and make it.
		var new_piece = Object.new()
		var piece_script = load(p["_script"])
		new_piece.set_script(piece_script)
		if new_piece is NoteJournalResource.Piece:
			new_piece.document = self
			new_piece._deserialize(p)
			pieces.append(new_piece)
	
	update_document_title()
	emit_changed()
	for c in children:
		c.parent = self
		c.saturate()

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

func swap_pieces(from: NoteJournalResource.Piece, to: NoteJournalResource.Piece):
	var from_index = pieces.find(from)
	var to_index = pieces.find(to)
	var place_holder_p = pieces[to_index]
	var place_holder_raw = piece_data[to_index]
	pieces[to_index] = from
	pieces[from_index] = place_holder_p
	piece_data[to_index] = piece_data[from_index]
	piece_data[from_index] = place_holder_raw
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

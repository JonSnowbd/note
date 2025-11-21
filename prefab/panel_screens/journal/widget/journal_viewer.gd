@tool
extends Control
class_name NoteJournalViewer

signal should_save

@export var initial_journal: NoteJournalResource
@export_file("*.gd") var list_of_widgets: Array[String]
@export_file("*.gd") var list_of_editor_only_widgets: Array[String]
@export var include_editor_widgets: bool = false
@export var document_viewing_root: Control

@export_group("Tree Related References")
@export var show_on_open_document: Control
@export var document_tree: Tree
@export var create_document_button: Button
@export var save_document_button: Button
@export var delete_document_button: Button

@export_group("Other References")
@export var widget_palette_root: Container
@export var widget_palette: Container

var current_journal: NoteJournalResource = null
var open_document: NoteJournalDocument = null
var open_document_chunks: Array[NoteJournalChunkEditor] = []

var sidebar_animation_contract: StableControlAnimator

var _delete_timeout: float = -1.0

func _ready() -> void:
	document_tree.nothing_selected.connect(_no_item_selected)
	document_tree.item_selected.connect(_new_item_selected)
	create_document_button.pressed.connect(create_document)
	delete_document_button.pressed.connect(delete_document)
	save_document_button.pressed.connect(_save)
	
	sidebar_animation_contract = StableControlAnimator.new(widget_palette_root)
	
	if initial_journal != null:
		set_journal(initial_journal)
	
	show_on_open_document.hide()

func _process(delta: float) -> void:
	if _delete_timeout >= 0.0:
		_delete_timeout -= delta
	if widget_palette_root.visible:
		var mouse_from_edge = ((size.x-200.0)-get_local_mouse_position().x) / 200.0
		mouse_from_edge = clamp(1.0-mouse_from_edge, 0.0, 1.0)
		
		sidebar_animation_contract.offset.x = lerp(widget_palette_root.size.x+60.0, 0.0, mouse_from_edge)

func set_journal(new_journal: NoteJournalResource):
	if current_journal != null:
		current_journal.tree_changed.disconnect(update_tree)
	current_journal = new_journal
	for c in current_journal.documents:
		c.saturate()
	update_tree()
	update_widget_palette()
	current_journal.tree_changed.connect(update_tree)

func _no_item_selected():
	if current_journal == null: return
	close_open_document()
	document_tree.deselect_all()
func _new_item_selected():
	if current_journal == null: return
	var item = document_tree.get_selected()
	if item == null:
		close_open_document()
	else:
		var uuid = item.get_metadata(0)
		if uuid != "":
			set_open_document(uuid)
		else:
			close_open_document()
func _save():
	should_save.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_save()
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_save()
	
func update_widget_palette():
	const PickupScript = preload("uid://cxj8y7idv21t")
	for child in widget_palette.get_children():
		child.queue_free()
	for widget in list_of_widgets:
		var new_scr = Object.new()
		var script = load(widget)
		new_scr.set_script(script)
		
		if new_scr is NoteJournalResource.Piece:
			var bit = new_scr._make_entry()
			bit.set_script(PickupScript)
			bit.script_target = widget
			widget_palette.add_child(bit)
		
		new_scr.free()

func _create_entries_for(document: NoteJournalDocument, parent: TreeItem = null):
	var i = document_tree.create_item(parent)
	i.set_text(0,document.document_title)
	i.set_metadata(0, document.uuid)
	document._tree_item = i

	for subdoc in document.children:
		_create_entries_for(subdoc, i)
	
func update_tree():
	document_tree.clear()
	
	var root = document_tree.create_item()
	root.set_text(0, tr("Your Journal"))
	root.set_metadata(0, "")
	for document in current_journal.documents:
		_create_entries_for(document, root)

func create_document():
	if current_journal == null:
		return
	close_open_document()
	var parent: NoteJournalDocument = null
	var selected_document = document_tree.get_selected()
	if selected_document != null:
		parent = current_journal.find_document_by_uuid(selected_document.get_metadata(0))
	current_journal.create_new_document("New Document", parent)

func delete_document():
	if _delete_timeout < 0.0:
		_delete_timeout = 0.5
		return
	if current_journal == null:
		return
	close_open_document()
	var selected = document_tree.get_selected()
	if selected != null:
		var document = current_journal.find_document_by_uuid(selected.get_metadata(0))
		if document != null:
			current_journal.delete_document(document)
	_save()

func close_open_document():
	if open_document != null:
		open_document.new_piece_added.disconnect(_on_document_added_piece)
		open_document.deleted_piece.disconnect(_on_document_deleted_piece)
		for editor in open_document_chunks:
			if !is_instance_valid(editor):
				continue
			editor.delete.disconnect(_chunk_requested_delete)
			editor.swap_with.disconnect(_chunk_swap)
			editor.ending_edit.disconnect(_save)
			editor.source.forward_changes_to_document()
			editor.queue_free()
		open_document_chunks.clear()
	open_document = null
	show_on_open_document.hide()
	_save()

## Takes a UUID and set the viewer to display the document it finds.
func set_open_document(new_document_uuid: String):
	if open_document != null:
		close_open_document()
	var document = current_journal.find_document_by_uuid(new_document_uuid)
	if document == null:
		return
	show_on_open_document.show()
	open_document = document
	open_document.new_piece_added.connect(_on_document_added_piece)
	open_document.deleted_piece.connect(_on_document_deleted_piece)
	var new_chunks = document.create_representation_list()
	for chunk in new_chunks:
		chunk.delete.connect(_chunk_requested_delete.bind(chunk))
		chunk.swap_with.connect(_chunk_swap)
		chunk.ending_edit.connect(_save)
		document_viewing_root.add_child(chunk)
		open_document_chunks.append(chunk)
	open_document.update_document_title()

func _new_piece_request(at: int, script_path: String):
	if open_document != null:
		open_document.create_piece(at, script_path)
		open_document.update_document_title()
func _chunk_swap(from: NoteJournalResource.Piece, to: NoteJournalResource.Piece):
	if open_document != null:
		open_document.swap_pieces(from, to)
		open_document.update_document_title()
func _chunk_requested_delete(chunk: NoteJournalChunkEditor):
	if open_document != null:
		open_document.delete_piece(chunk.source)
		open_document.update_document_title()
		_save()
func _on_document_added_piece(at: int, piece: NoteJournalResource.Piece):
	if open_document != null:
		var chunk = open_document.create_editor_for_piece(piece)
		chunk.delete.connect(_chunk_requested_delete.bind(chunk))
		chunk.swap_with.connect(_chunk_swap)
		chunk.ending_edit.connect(_save)
		chunk.modulate.a = 0.0
		document_viewing_root.add_child(chunk)
		document_viewing_root.move_child(chunk, at)
		open_document_chunks.insert(at, chunk)
		var t = create_tween()
		t.tween_property(chunk, "modulate:a", 1.0, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		_save()
		open_document.update_document_title()
func _on_document_deleted_piece(at: int):
	if open_document != null:
		var target = document_viewing_root.get_child(at)
		document_viewing_root.remove_child(target)
		target.queue_free()
		open_document.update_document_title()

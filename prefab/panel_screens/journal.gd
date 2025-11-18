@tool
extends Control

const PieceWidgetType = preload("uid://c61suun3gwlta")
const PieceWidget = preload("uid://c12t5bm70xgkb")

@export_file("*.gd") var piece_prefabs: Array[String]

@export var tree: Tree
@export var create_button: Button
@export var save_button: Button
@export var delete_button: Button
@export var widget_palette: Container
@export var widget_popup: PopupPanel

@export var current_document_root: Control
@export var journal_path: String = "res://addons/note/_journal.res"

var journal: NoteJournalResource
var current_document: NoteJournalDocument
var delete_timeout: float = 0.0
var awaiting_widget_index: int = -1
var anchor_node: Control
var current_representations: Array[PieceWidgetType] = []
var currently_editing_item: TreeItem

func _ready() -> void:
	if FileAccess.file_exists(journal_path):
		journal = ResourceLoader.load(journal_path)
		journal.resource_path = journal_path
	else:
		journal = NoteJournalResource.new()
		journal.resource_path = journal_path
		_save()
	tree.item_activated.connect(_attempt_open_doc)
	tree.nothing_selected.connect(deselect)
	create_button.pressed.connect(create_document)
	delete_button.pressed.connect(delete_document)
	save_button.pressed.connect(_save)
	widget_popup.popup_hide.connect(_clear_widget_awaiting)
	for c in journal.documents:
		c.saturate()
	update_tree()
	update_widget_palette()

func _attempt_open_doc():
	if current_document != null:
		close_document()
	var selected = tree.get_selected()
	if selected == null:
		return
	currently_editing_item = selected
	var uuid = selected.get_metadata(0)
	var doc = find_by_uuid(uuid)
	if doc != null:
		open_document(doc)

func _clear_widget_awaiting():
	awaiting_widget_index = -1

func _save():
	if current_document != null:
		sync_data_back_to_document()
	if journal != null:
		ResourceSaver.save(journal, journal_path)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_save()

func hide_all_editors_but(choice: PieceWidgetType):
	for i in current_representations:
		if i != choice:
			i.hide_edit_tool()
			i.modulate.a = 0.4
func show_all_editors_but(choice: PieceWidgetType):
	for i in current_representations:
		if i != choice:
			i.show_edit_tool()
			i.modulate.a = 1.0
func _process(delta: float) -> void:
	if delete_timeout >= 0.0:
		delete_timeout -= delta
func _physics_process(delta: float) -> void:
	if widget_popup.visible:
		if !is_instance_valid(anchor_node):
			anchor_node = null
			return
		widget_popup.position = anchor_node.global_position+anchor_node.size*Vector2(0.0, 1.0)
		if Engine.is_editor_hint():
			var vp = get_window().position
			widget_popup.position += vp
	
func update_widget_palette():
	for item in widget_palette.get_children():
		item.queue_free()
	for i in piece_prefabs:
		var script = load(i)
		var obj = Object.new()
		obj.set_script(script)
		var btn = obj._make_entry() as Button
		btn.pressed.connect(func():
			if awaiting_widget_index == -1:
				return
			current_document.pieces.insert(awaiting_widget_index, {
				"_type" = i,
				"_uuid" = UUID.v4()
			})
			refresh_document()
			widget_popup.hide()
		)
		widget_palette.add_child(btn)
		obj.free()

func _create_entries_for(document: NoteJournalDocument, parent: TreeItem = null):
	var i = tree.create_item(parent)
	i.set_text(0,document.document_title)
	i.set_metadata(0, document.uuid)
	for subdoc in document.children:
		_create_entries_for(subdoc, i)
func update_tree():
	tree.clear()
	for i in range(len(journal.documents)):
		_create_entries_for(journal.documents[i])
func deselect():
	tree.deselect_all()
func on_tree_selection_change():
	var selected = tree.get_selected()
	if selected == null:
		create_button.disabled = true
		delete_button.disabled = true
		return
	var selected_doc = find_by_uuid(selected.get_metadata(0))
	if selected_doc == null:
		create_button.disabled = false
		delete_button.disabled = true

func create_document():
	var selected = tree.get_selected()
		
	var new_document = NoteJournalDocument.new()
	new_document.pieces.append({
		"_type" = "uid://btvdvje538ery"
	})
	new_document.saturate()
	if selected != null:
		var selected_doc = find_by_uuid(selected.get_metadata(0))
		if selected_doc != null:
			selected_doc.children.append(new_document)
			new_document.parent = selected_doc
	else:
		journal.documents.append(new_document)
	update_tree()

func delete_document():
	if delete_timeout > 0.0:
		var selected = tree.get_selected()
		var selected_doc = find_by_uuid(selected.get_metadata(0))
		if selected_doc != null:
			if current_document == selected_doc:
				close_document()
			if selected_doc.parent != null:
				selected_doc.parent.children.erase(selected_doc)
				selected_doc.parent = null
			else:
				journal.documents.erase(selected_doc)
			update_tree()
	delete_timeout = 0.5

func _find_inner(target: NoteJournalDocument, uuid: String) -> NoteJournalDocument:
	if target.uuid == uuid:
		return target
	for c in target.children:
		var doc = _find_inner(c, uuid)
		if doc != null:
			return doc
	return null
func find_by_uuid(uuid: String) -> NoteJournalDocument:
	for c in journal.documents:
		var doc = _find_inner(c, uuid)
		if doc != null:
			return doc
	return null

func sync_data_back_to_document():
	if current_document == null:
		return
	for c: PieceWidgetType in current_representations:
		c.reference.forward_changes_to_document()
		
func refresh_document():
	sync_data_back_to_document()
	if current_document != null:
		open_document(current_document)
func close_document():
	_save()
	current_document = null
	for c in current_document_root.get_children():
		c.queue_free()
	currently_editing_item = null
func open_document(doc: NoteJournalDocument):
	current_document = doc
	if doc == null:
		return
	current_representations.clear()
	for c in current_document_root.get_children():
		c.queue_free()
	var container = VBoxContainer.new()
	
	var line_edit = LineEdit.new()
	line_edit.text = current_document.document_title
	line_edit.text_changed.connect(func(new_title):
		current_document.document_title = new_title
		if currently_editing_item != null:
			currently_editing_item.set_text(0, new_title)
	)
	line_edit.text_submitted.connect(func(_st):
		line_edit.release_focus()
	)
	
	container.add_child(line_edit)
	
	for p in doc.pieces:
		var piece_script = load(p["_type"]) as Script
		var new_piece = Object.new()
		new_piece.set_script(piece_script)
		if new_piece is NoteJournalResource.Piece:
			new_piece.root = journal
			new_piece.document = doc
			new_piece._deserialize(p)
		var rep: PieceWidgetType = PieceWidget.instantiate()
		rep.reference = new_piece as NoteJournalResource.Piece
		rep.upwards_request.connect(func():
			anchor_node = rep.up_add
			awaiting_widget_index = doc.pieces.find(p)
			widget_popup.show()
		)
		rep.downwards_request.connect(func():
			anchor_node = rep.down_add
			awaiting_widget_index = doc.pieces.find(p)+1
			widget_popup.show()
		)
		rep.edit_started.connect(func():
			hide_all_editors_but(rep)
		)
		rep.edit_ended.connect(func():
			show_all_editors_but(rep)
		)
		
		current_representations.append(rep)
		container.add_child(rep)
	
	current_document_root.add_child(container)

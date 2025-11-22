@tool
extends Control
class_name NoteJournalChunkEditor

signal starting_edit
signal ending_edit
signal delete
signal swap_with(from: NoteJournalResource.Piece, to: NoteJournalResource.Piece)

@export var drag_theme: Theme

@export_group("Slot")
@export var viewer_slot: Control
@export var editor_slot: Control
@export_group("Controls References")
@export var chunk_label: Label
@export var edit_button: Button
@export var background_panel: Control
@export_group("Root References")
@export var chunk_content_root: Control
@export var chunk_editor_root: Control
@export_group("Editor Piece References")
@export var chunk_editor_title_edit: LineEdit
@export var chunk_editor_done_button: Button
@export var chunk_editor_delete_button: Button


var source: NoteJournalResource.Piece
var document: NoteJournalDocument
var is_editing: bool = false
var _tween: Tween

func _ready() -> void:
	if is_part_of_edited_scene(): return
	edit_button.modulate.a = 0.0
	edit_button.pressed.connect(begin_edit)
	chunk_editor_delete_button.pressed.connect(delete.emit)
	chunk_editor_done_button.pressed.connect(end_edit)
	chunk_editor_title_edit.text_changed.connect(set_chunk_title)
	
	background_panel.self_modulate.a = 0.0
	chunk_content_root.hide()
	chunk_editor_root.hide()
	
	edit_button.set_drag_forwarding(forwarded_get_drag, forwarded_can_drop, forwarded_on_drop)

func forwarded_get_drag(at: Vector2) -> Variant:
	if source == null: return null
	var p = PanelContainer.new()
	var label = Label.new()
	label.text = source.title
	p.custom_minimum_size = Vector2(32,32)
	p.add_child(label)
	p.theme = drag_theme
	set_drag_preview(p)
	return self
func forwarded_can_drop(at: Vector2, data: Variant):
	return source != null and data is NoteJournalChunkEditor
func forwarded_on_drop(at: Vector2, data: Variant):
	if data is NoteJournalChunkEditor:
		var outgoing = source
		var incoming = data.source
		data.set_source(outgoing)
		set_source(incoming)
		swap_with.emit(incoming, outgoing)

func set_background(visibility: float = 1.0):
	if _tween != null:
		_tween.stop()
	_tween = create_tween()
	_tween.tween_property(background_panel, "self_modulate:a", visibility, 0.75)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_CUBIC)

func begin_edit():
	chunk_label.hide()
	edit_button.hide()
	is_editing = true
	chunk_content_root.hide()
	chunk_editor_root.show()
	starting_edit.emit()
	set_background(1.0)
func end_edit():
	if source != null:
		source.forward_changes_to_document()
	chunk_label.visible = !chunk_label.text.is_empty()
	edit_button.show()
	is_editing = false
	chunk_content_root.show()
	chunk_editor_root.hide()
	ending_edit.emit()
	set_background(0.0)

func delete_chunk():
	delete.emit()

func set_chunk_title(new_title: String):
	if source != null:
		source.set_title(new_title)
		chunk_label.text = new_title
func hide_edit_button():
	var t = create_tween()
	t.tween_property(edit_button, "modulate:a", 0.0, 0.2)
func show_edit_button():
	var t = create_tween()
	t.tween_property(edit_button, "modulate:a", 1.0, 0.2)
func set_source(new_source: NoteJournalResource.Piece):
	for c in viewer_slot.get_children():
		c.queue_free()
	for c in editor_slot.get_children():
		c.queue_free()
	source = new_source
	if source != null:
		chunk_label.visible = !source.title.is_empty()
		chunk_label.text = source.title
		var chunk_viewer = new_source._make_rep()
		var chunk_editor = new_source._make_editor()
		
		viewer_slot.add_child(chunk_viewer)
		editor_slot.add_child(chunk_editor)
		
		chunk_editor_root.hide()
		chunk_content_root.call_deferred("show")
		chunk_editor_title_edit.text = source.title
	else:
		chunk_label.text = tr("Awaiting chunk")
		chunk_content_root.hide()
		chunk_editor_root.hide()
	is_editing = false

func _input(event: InputEvent) -> void:
	if !is_editing:
		return
	if !event.is_pressed(): return
	if event is InputEventMouseButton:
		var rect = get_rect()
		rect.position = Vector2.ZERO
		if event.button_index == MOUSE_BUTTON_LEFT and !rect.has_point(get_local_mouse_position()):
			end_edit()

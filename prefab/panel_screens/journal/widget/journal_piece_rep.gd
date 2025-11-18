@tool
extends Control

signal upwards_request
signal downwards_request
signal edit_started
signal edit_ended
signal delete_request

@export var root: Control
@export var edit_button: Button
@export var title_label: Label
@export var popup: PopupPanel
@export var editor_root: Control
@export var done_button: Button
@export var delete_button: Button
@export var up_add: Button
@export var down_add: Button
@export var alpha_root: Control
@export var title_edit: LineEdit

var reference: NoteJournalResource.Piece :
	set(val):
		if reference != null:
			reference.changed.disconnect(update)
		reference = val
		update()
		
var root_rep: Control

func _ready() -> void:
	popup.hide()
	edit_button.pressed.connect(edit)
	up_add.pressed.connect(upwards_request.emit)
	down_add.pressed.connect(downwards_request.emit)
	title_edit.text_changed.connect(updated_title)
	popup.popup_hide.connect(func():
		edit_ended.emit()
		title_label.modulate.a = 0.6
	)
	popup.about_to_popup.connect(edit_started.emit)
	done_button.pressed.connect(popup.hide)
	delete_button.pressed.connect(delete_request.emit)

func clear_root():
	for c in root.get_children():
		c.queue_free()
	for c in editor_root.get_children():
		c.queue_free()

func update():
	clear_root()
	title_label.text = reference.title
	title_edit.text = title_label.text
	root.add_child(reference._make_rep())
	editor_root.add_child(reference._make_editor())

func edit():
	popup.popup()
	title_label.modulate.a = 0.0

func show_edit_tool():
	alpha_root.show()
func hide_edit_tool():
	alpha_root.hide()

func updated_title(new_text: String):
	if reference != null:
		reference.title = new_text
		title_label.text = new_text

func _process(delta: float) -> void:
	var mp = edit_button.get_local_mouse_position()
	var dest = edit_button.size*Vector2(0.5, 0.5)
	var dist = clamp(mp.distance_to(dest)/300.0, 0.0, 1.0)
	alpha_root.modulate.a = 1.0-clamp(dist*1.3,0.0, 0.85)
	
	if popup.visible:
		var rp = get_window().position
		var v = Vector2(float(rp.x), float(rp.y))
		if Engine.is_editor_hint():
			popup.position = v +global_position+(size*Vector2(0.0, 1.0))
		else:
			popup.position = global_position+(size*Vector2(0.0, 1.0))
		popup.size.x = size.x
		popup.size.y = 375.0

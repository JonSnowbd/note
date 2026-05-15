extends MarginContainer

@export var col_window_blackout: Color
@export var col_window_fadeout: Color

@export_group("Refs")
@export var ref_blackout: ColorRect
@export var ref_window_container: Container

var current_window: NoteWindow

func _ready() -> void:
	hide()
	ref_window_container.hide()
	ref_blackout.hide()

func _close(close_shutters: bool = true):
	if current_window != null:
		var win = current_window
		current_window = null
		var t = create_tween()
		t.tween_property(current_window, "modulate:a", 0.0, 0.2)
		t.tween_callback(current_window.queue_free)
	if close_shutters:
		var t = create_tween()
		t.tween_property(ref_blackout, "color", col_window_fadeout, 0.25)
		t.tween_callback(ref_window_container.hide)

## Takes a window scene, which could be a path, a packed scene, or an already
## created node, to popup into the viewport, blocking input. This will return
## the window, before it appears.
func popup_window(window_scene, fade_in: float = 0.4, interrupt_focus: bool = true) -> NoteWindow:
	if interrupt_focus:
		note.focus.deactivate()
	var t = note.util.clean_tween("__note_window")
	if current_window != null:
		note.warn("Popup window called while window already exists, closing current window.")
		_close(false)
	var new_window: NoteWindow = null
	if window_scene is String:
		new_window = note.loading_screen.force_fetch(window_scene).instantiate()
	elif window_scene is PackedScene:
		new_window = window_scene.instantiate()
	elif window_scene is NoteWindow:
		if window_scene.get_parent() != null:
			window_scene.get_parent().remove_child(window_scene)
		new_window = window_scene
	new_window.closed.connect(_close)
	return new_window

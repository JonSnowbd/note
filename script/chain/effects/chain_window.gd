extends ChainNode
class_name ChainWindow

## This should be a packed scene with a NoteWindow type at the root,
## this will be opened.
@export var window_scene: PackedScene
@export var blackout_color: Color = Color(0.0,0.0,0.0,0.0)
@export var interrupt_focus: bool = true

var current_window: NoteWindow

func _chain_start(instance: RunInstance):
	if current_window != null: note.error("Chain Window called despite already having a window open.")
	current_window = note.ui.window(window_scene, blackout_color)

func _chain_work(instance: RunInstance, delta: float) -> Response:
	if !is_instance_valid(current_window) or current_window.is_queued_for_deletion():
		return Response.DONE
	if note.ui.current_window == current_window:
		return Response.WORKING
	return Response.DONE

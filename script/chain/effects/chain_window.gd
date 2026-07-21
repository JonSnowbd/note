extends ChainNode
class_name ChainWindow

@export var window_scene: PackedScene
@export var fade_in: float = 0.4
@export var interrupt_focus: bool = true

var current_window: NoteWindow

func _chain_start(instance: RunInstance):
	pass

func _chain_work(instance: RunInstance, delta: float) -> Response:
	return Response.DONE

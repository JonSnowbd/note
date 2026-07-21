extends ChainNode
class_name ChainFXPrint

@export_multiline var message: String
@export var header: String = "Note"
@export_enum("Info", "Warning", "Error") var severity: int = 0

func _chain_start(_instance: RunInstance):
	is_instant = true
	match severity:
		0: note.info("%d - %s"%[Engine.get_process_frames(), message], header)
		1: note.warn(message, header)
		2: note.error(message)
func _chain_work(_instance: RunInstance, _delta: float) -> Response:
	return Response.DONE

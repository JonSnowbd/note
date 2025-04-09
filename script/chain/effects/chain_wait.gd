extends ChainFX
class_name ChainWait

## This chain node simply waits for a bit.

@export var duration: float = 1.0

var timeout: float = 0.0

func _process(delta: float) -> void:
	if timeout > 0.0:
		timeout -= (delta*time_scale)
		if timeout <= 0.0:
			on_finish.emit()
func _start(data):
	timeout = duration
	on_start.emit()
func _done() -> bool:
	return timeout <= 0.0

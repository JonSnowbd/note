extends ChainNode
class_name ChainWaitFrames

## This chain node simply waits for a set amount of frames before being finished.
## Useful for Sequential type chains to add spacing between events.

@export var duration: int = 30

func _chain_start(instance: RunInstance):
	instance.data.set(&"wait_chain_timer", duration)
func _chain_work(instance: RunInstance, delta: float) -> Response:
	var t = instance.data.get(&"wait_chain_timer", duration)
	t -= delta
	if t <= 0.0:
		return Response.DONE
	instance.data.set(&"wait_chain_timer", t)
	return Response.WORKING

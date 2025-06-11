extends ChainFX
class_name ChainBlackout

## Calls into Note's default blackout canvas, useful for hiding transitions
## The context is not used in this effect.

@export var fade_in: float = 0.2
@export var duration: float = 1.0
@export var fade_out: float = 0.2
@export var color: Color

var _trip: bool = false

func _process(delta: float) -> void:
	if _trip:
		var alpha_gate = min(color.a*0.1, 0.1)
		if note.blackout.color.a > alpha_gate:
			_trip = false
func _start(data):
	_trip = true
	note.temporary_blackout(fade_in, duration, fade_out, color)
func _done() -> bool:
	return !_trip and note.blackout.color.a <= 0.025 

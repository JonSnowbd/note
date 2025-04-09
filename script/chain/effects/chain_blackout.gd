extends ChainFX
class_name ChainBlackout

## Calls into Note's default blackout canvas, useful for hiding transitions
## The context is not used in this effect.

@export var end_after_fade: bool = true
@export var fade_in: float = 0.2
@export var duration: float = 1.0
@export var fade_out: float = 0.2
@export var color: Color

var timeout: float = 0.0

func _process(delta: float) -> void:
	if end_after_fade and timeout > 0.0:
		timeout -= delta

func _start(data):
	if end_after_fade:
		timeout = fade_in
	else:
		timeout = fade_in+fade_out+duration
	note.temporary_blackout(fade_in, duration, fade_out, color)
func _done() -> bool:
	return timeout <= 0.0

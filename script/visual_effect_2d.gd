extends Node2D
class_name VisualEffect2D


@export var effect_duration: float = 1.5
@export var effect_fadeout: float = 0.5

## How long this visual effect has been alive.
var life: float = 0.0
## Modifies how fast or slow this effect ages.
var time_scale: float = 1.0

func _process(delta: float) -> void:
	life += (delta*time_scale)
	var theta = clamp(life / effect_duration, 0.0, 1.0)
	if life > effect_duration:
		var death_theta = clamp((life - effect_duration), 0.0, effect_fadeout) / effect_fadeout
		modulate.a = 1.0-death_theta
		if life >= effect_duration+effect_fadeout:
			queue_free()

func effect_process(delta: float, completion: float):
	pass
func effect_trigger(data):
	pass

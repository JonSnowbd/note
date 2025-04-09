extends RefCounted
class_name AutoStateEffect

## Higher priority = executed first
var _effect_priority: float = 0.0
var _effect_duration: float = -1.0
var _effect_lifetime: float = -1.0

func effect_get_completion() -> float:
	if _effect_duration < 0.0:
		return 0.0
	return _effect_lifetime / _effect_duration
func effect_get_inverse_completion() -> float:
	return 1.0-effect_get_completion()


## Abstract: Do things to the calculator.
func apply(obj: AutoStateCalculator):
	pass

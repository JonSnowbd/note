extends RefCounted
class_name AutoStateEffect

## Higher priority = executed first
var _effect_priority: float = 0.0
## How long the effect was intended to exist for, negative
## values indicate an infinite effect.
var _effect_duration: float = -1.0
## How long this effect has currently been active for.
var _effect_lifetime: float = -1.0
## Ephemeral effects do not survive an effect purge, use this
## for effects with node references, so that re-hydrating
## saves are not subject to unintended behaviour.
var _effect_ephemeral: bool = false


## Returns a number, 0.0 means the effect just started,
## and 1.0 means it is about to end. For infinite 
## effects this is always 0.0
func effect_get_completion() -> float:
	if _effect_duration < 0.0:
		return 0.0
	return _effect_lifetime / _effect_duration
## Returns a number, 1.0 means the effect just started,
## and 0.0 means it is about to end. For infinite 
## effects this is always 1.0
func effect_get_inverse_completion() -> float:
	return 1.0-effect_get_completion()

## ABSTRACT: Do things to the calculator.
func apply(obj: AutoStateCalculator):
	pass

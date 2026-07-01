@abstract
extends RefCounted
class_name AutoStateEffect

## The base type for all status effects inside of an Auto State Calculator.
## By only implementing what is needed to apply an effect, an absolute clean
## stack can be achieved very easily.

## Emitted when the effect is applied,
signal raising_event(data)
## Emitted when the effect has determined it should be removed of its own accord,
## outside of removal and expiration.
signal invalidated

## Higher priority = executed first
var _effect_priority: float = 0.0
## How long the effect was intended to exist for, negative
## values indicate an infinite effect.
var _effect_duration: float = -1.0
## How long this effect has currently been active for.
var _effect_lifetime: float = -1.0
var _effect_creation_date: int = 0
## A list of enum values applied to this effect. Use this to mark effects states such as
## Temporary Effects, Identity Effects, Positive Effects, etc
var _effect_tags: Array[int] = []

func effect_raise(data = null):
	raising_event.emit(data)
## Returns true if the effect has the specified tag.
func effect_is_tagged(tag: int) -> bool:
	return _effect_tags.has(tag)
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

@abstract
func apply(obj: AutoStateCalculator)

func consume(obj: AutoStateCalculator, event):
	pass

extends RefCounted
class_name AutoStateCalculator

## An AutoStateCalculator object helps organize a complex rpg system, and maintains
## simplicity by simply wiping the block and bit by bit re-applying every effect.
## Updates are a bit slow but completely fine until you need this updating every frame
## on thousands of units.
##
## A statcore has an array of Effectors, and can each be literally anything, from
## items equipped, to de/buffs, to character stat definitions.

## Called when an effect is explicitly added to the calculator.
signal effect_added(effect: AutoStateEffect)
## Calls when an effect is removed by running out of life
signal effect_expired(effect: AutoStateEffect)
## Called when an effect is removed by force via remove or remove_effects_of_type
signal effect_removed(effect: AutoStateEffect)

## Assign a context if you want your effects to look at this for information
var context
## A list of every effect affecting this calculator. Do not manipulate this
## manually.
var effects: Array[AutoStateEffect] = []
## If the
var oldest_effects_first: bool = false

func _filter_effects(item: AutoStateEffect) -> bool:
	var keep = item._effect_duration < 0.0 or item._effect_lifetime < item._effect_duration
	if !keep:
		effect_expired.emit(item)
	return keep
func _filter_ephemeral(item: AutoStateEffect) -> bool:
	if item._effect_ephemeral:
		effect_removed.emit(item)
	return !item._effect_ephemeral
func _sort_effects(lhs: AutoStateEffect, rhs: AutoStateEffect) -> bool:
	if lhs._effect_priority == rhs._effect_priority:
		if lhs._effect_lifetime == rhs._effect_lifetime:
			return false
		return lhs._effect_lifetime > rhs._effect_lifetime
	return lhs._effect_priority > rhs._effect_priority

## Forces the core to recalculate the state to be up to date.
## This happens each time update is called, and on operations
## where this makes sense, so there shouldn't be 
## a need to use this manually.
func recalculate(deep_clean: bool = false) -> void:
	core_reset()
	if deep_clean:
		effects = effects.filter(_filter_effects)
		effects.sort_custom(_sort_effects)
	for e: AutoStateEffect in effects:
		e.apply(self)

func remove_ephemeral_effects() -> void:
	pass
func remove_all_effects() -> void:
	pass
## Removes all effects of the given type, and recalculates.
func remove_effects_of_type(type) -> void:
	effects = effects.filter(func(item):
		var keep = !is_instance_of(item, type)
		if !keep:
			effect_removed.emit(item)
		return keep
	)
	effects.sort_custom(_sort_effects)
	recalculate()

## Adds an effect to the core, and recalculates. Priority and lifespan
## will be set explicitly through this method, so do not assign it yourself
## on the effect instance
func add_effect(new_effect: AutoStateEffect, priority: float = 0.0, duration: float = -1.0):
	new_effect._effect_priority = priority
	new_effect._effect_duration = duration
	if new_effect._effect_duration >= 0.0:
		new_effect._effect_lifetime = 0.0
	else:
		new_effect._effect_lifetime = -1.0
	effects.append(new_effect)
	recalculate(true)
	effect_added.emit(new_effect)

## Returns true if the calculator is under the influence of any effect of this type.
func has_effect_type(effector_type: Script) -> bool:
	for e in effects:
		if is_instance_of(e, effector_type):
			return true
	return false

## Returns the first instance(lowest priority) that is, or is a descendant
## of the provided type.
func get_effect(effector_type) -> AutoStateEffect:
	for e in effects:
		if is_instance_of(e, effector_type):
			return e
	return null
## Returns every instance that is, or is a descendant
## of the provided type.
func get_effects(effector_type) -> Array[AutoStateEffect]:
	var store: Array[AutoStateEffect] = []
	for e in effects:
		if is_instance_of(e, effector_type):
			store.append(e)
	return store

func update(dt: float):
	var clear_after: bool = false
	for e in effects:
		e._effect_lifetime += dt
		if e._effect_duration >= 0.0 and e._effect_lifetime >= e._effect_duration:
			clear_after = true
	if clear_after:
		recalculate(true)
	else:
		recalculate(false)

## ABSTRACT: VERY IMPORTANT. In this method you should reset every stat to its default.
## It is recommended to model character stats as an effect, rather than having calculators
## with different defaults.
func core_reset():
	pass

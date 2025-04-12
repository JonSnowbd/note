extends RefCounted
class_name AutoStateCalculator

## A statcore object helps organize a complex rpg system, and maintains
## simplicity by simply wiping the block and bit by bit re-applying every effect.
## Updates are a bit slow but completely fine until you need this updating every frame
## on thousands of units.
##
## A statcore has an array of Effectors, and can each be literally anything, from
## items equipped to debuffs.


signal updated()
## Called when an effect is explicitly added to the calculator.
signal effect_added(effect: AutoStateEffect)
## Calls when an effect is removed by running out of life
signal effect_expired(effect: AutoStateEffect)
signal effect_removed(effect: AutoStateEffect)

var effects: Array[AutoStateEffect] = []
var context

func _filter_effects(item: AutoStateEffect) -> bool:
	var keep =  item._effect_duration < 0.0 or item._effect_lifetime < item._effect_duration
	if !keep:
		effect_expired.emit(item)
	return keep
func _sort_effects(lhs: AutoStateEffect, rhs: AutoStateEffect) -> bool:
	if lhs._effect_priority == rhs._effect_priority:
		if lhs._effect_lifetime == rhs._effect_lifetime:
			return true
		return lhs._effect_lifetime > rhs._effect_lifetime
	return lhs._effect_priority > rhs._effect_priority

func core_recalc(deep_clean: bool = false):
	core_reset()
	if deep_clean:
		effects = effects.filter(_filter_effects)
		effects.sort_custom(_sort_effects)
	for e in effects:
		e.apply(self)
	updated.emit()

func remove_effects_of_type(type):
	effects = effects.filter(func(item):
		var keep = !is_instance_of(item, type)
		if !keep:
			effect_removed.emit(item)
		return keep
	)
	effects.sort_custom(_sort_effects)
	core_recalc()

func add_effect(new_effect, priority: float = 0.0, duration: float = -1.0):
	if new_effect is AutoStateEffect:
		new_effect._effect_priority = priority
		new_effect._effect_duration = duration
		if new_effect._effect_duration >= 0.0:
			new_effect._effect_lifetime = 0.0
		else:
			new_effect._effect_lifetime = -1.0
		effects.append(new_effect)
		core_recalc(true)
		effect_added.emit(new_effect)
	else:
		push_warning("Attempted to add an effector that was not derived from NoteStateCoreEffector")

## Returns true if the calculator is under the influence of any effect of this type.
func has_effect_type(effector_type: Script) -> bool:
	for e in effects:
		if is_instance_of(e, effector_type):
			return true
	return false
func get_effect(effector_type) -> AutoStateEffect:
	for e in effects:
		if is_instance_of(e, effector_type):
			return e
	return null
func get_effects(effector_type) -> Array[AutoStateEffect]:
	var store: Array[AutoStateEffect] = []
	for e in effects:
		if is_instance_of(e, effector_type):
			store.append(e)
	return store

func update(dt: float):
	var clear_after: bool = false
	for e in effects:
		if e._effect_duration >= 0.0:
			e._effect_lifetime += dt
			if e._effect_lifetime >= e._effect_duration:
				clear_after = true
	if clear_after:
		core_recalc(true)
	else:
		core_recalc(false)

## ABSTRACT: VERY IMPORTANT. In this method you should reset every stat to its default.
func core_reset():
	pass

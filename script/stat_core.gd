extends RefCounted
class_name NoteStatCore

## A statcore object helps organize a complex rpg system, and maintains
## simplicity by simply wiping the block and bit by bit re-applying every effect.
## Updates are a bit slow but completely fine until you need this updating every frame
## on thousands of units.
##
## A statcore has an array of Effectors, and can each be literally anything, from
## items equipped to debuffs.


signal updated()
signal effector_added(effector)
signal effector_expired(effector)
signal effector_removed(effector)

## If true the entire stack is recalculated each tick. This is necessary
var high_priority: bool = true
var effectors: Array[NoteStatCoreEffector] = []
var context

func _filter_effects(item: NoteStatCoreEffector) -> bool:
	var keep =  item.effector_duration < 0.0 or item.effector_lifetime < item.effector_duration
	if !keep:
		effector_expired.emit(item)
	return keep
func _sort_effects(lhs: NoteStatCoreEffector, rhs: NoteStatCoreEffector) -> bool:
	if lhs.effector_priority == rhs.effector_priority:
		if lhs.effector_lifetime == rhs.effector_lifetime:
			return true
		return lhs.effector_lifetime > rhs.effector_lifetime
	return lhs.effector_priority > rhs.effector_priority

func core_recalc(deep_clean: bool = false):
	core_reset()
	if deep_clean:
		effectors = effectors.filter(_filter_effects)
		effectors.sort_custom(_sort_effects)
	for e in effectors:
		e.effector_apply(self)
	updated.emit()

func effector_clear(type):
	effectors = effectors.filter(func(item):
		var keep = !is_instance_of(item, type)
		if !keep:
			effector_removed.emit(item)
		return keep
	)
	effectors.sort_custom(_sort_effects)
	core_recalc()
func effector_add(new_effect, priority: float = 0.0, duration: float = -1.0):
	if new_effect is NoteStatCoreEffector:
		new_effect.effector_priority = priority
		new_effect.effector_duration = duration
		if new_effect.effector_duration >= 0.0:
			new_effect.effector_lifetime = 0.0
		else:
			new_effect.effector_lifetime = -1.0
		effectors.append(new_effect)
		core_recalc(true)
		effector_added.emit(new_effect)
	else:
		push_warning("Attempted to add an effector that was not derived from NoteStateCoreEffector")

func effector_has(effector_type: Script) -> bool:
	for e in effectors:
		if effector_type.instance_has(e):
			return true
	return false
func effector_get_single(effector_type) -> NoteStatCoreEffector:
	for e in effectors:
		if e.is_class(str(effector_type)):
			return e
	return null
func effector_get_multi(effector_type) -> Array[NoteStatCoreEffector]:
	var store: Array[NoteStatCoreEffector] = []
	for e in effectors:
		if is_instance_of(e, effector_type):
			store.append(e)
	return store
## ABSTRACT: IMPLEMENT
func core_reset():
	pass
func core_tick(dt: float):
	var clear_after: bool = false
	for e in effectors:
		if e.effector_duration >= 0.0:
			e.effector_lifetime += dt
			if e.effector_lifetime >= e.effector_duration:
				clear_after = true
		e.effector_tick(self, dt)
	if clear_after:
		core_recalc(true)
	elif high_priority:
		core_recalc(false)

@abstract
extends Node
class_name PECSSystem

signal requesting_looker_validation

@export var priority: int = 0


class Looker extends Object:
	var filter_needs: Array[Script] = []
	var filter_without: Array[Script] = []
	var list: Array[PECSEntityMarker] = []
	var dirty_looker: bool = true
	func consider(ent: PECSEntityMarker):
		var already_listening: bool = list.has(ent)
		var is_valid: bool = true
		for component_required in filter_needs:
			if !ent.has_component(component_required):
				is_valid = false
				break
		for component_not_wanted in filter_without:
			if ent.has_component(component_not_wanted):
				is_valid = false
				break
		if already_listening and !is_valid:
			list.erase(ent)
		if !already_listening and is_valid:
			list.append(ent)
	func setup(has: Array[Script], without: Array[Script]):
		filter_needs = has
		filter_without = without
		dirty_looker = true
	func get_entities() -> Array[PECSEntityMarker]:
		## TODO, checks for dirty looker.
		return list

var looker_instance: Looker

@abstract
func setup(look:Looker)
@abstract
func run(look: Looker, delta: float)

func tagged_entity_process(entity: PECSEntityMarker, delta: float):
	pass

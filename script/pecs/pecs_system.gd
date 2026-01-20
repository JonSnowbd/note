@abstract
extends Node
class_name PECSSystem

signal requesting_looker_validation

@export var priority: int = 0

@abstract
func setup(core: PECSCore)
@abstract
func run(delta: float)

func tagged_entity_process(entity: PECSEntityMarker, delta: float):
	pass

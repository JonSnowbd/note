@abstract
extends Node
class_name PECSSystem

@export var priority: int = 0

@abstract
func setup(core: PECSCore)
@abstract
func run(delta: float)

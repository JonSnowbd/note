@abstract
@icon("res://addons/note/texture/icon/pecs/system.svg")
extends Node
class_name PECSSystem

@export var priority: int = 0

@abstract
func setup(core: PECSCore)
@abstract
func run(delta: float)

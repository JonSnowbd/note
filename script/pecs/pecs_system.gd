@abstract
@icon("res://addons/note/texture/icon/pecs/system.svg")
extends Node
class_name PECSSystem

## Higher = Ran first.
@export var priority: int = 0
var _internal_index: int = -1

@abstract
func setup(core: PECSCore)
@abstract
func run(delta: float)

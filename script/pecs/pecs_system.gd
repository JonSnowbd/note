@abstract
@icon("res://addons/note/texture/icon/pecs/system.svg")
extends Node
class_name PECSSystem

## Extend this to create a system that runs every frame in your PECSCore.

## Higher = Ran first.
@export var priority: int = 0
var _internal_index: int = -1

@abstract
func setup(core: PECSCore)
@abstract
func run(delta: float)

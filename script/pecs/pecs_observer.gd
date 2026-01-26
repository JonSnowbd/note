@abstract
@icon("res://addons/note/texture/icon/pecs/observer.svg")
extends Node
class_name PECSObserver

@export_enum("After All Systems", "When Raised") var event_bubble_behaviour: int = 0
@export var priority: int = 0
var _listening_to: Dictionary[Variant, bool] = {}

func listen(event):
	_listening_to[event] = true
func unlisten(event):
	_listening_to[event] = false

func is_interested_in(event) -> bool:
	return _listening_to.get(event, false)

@abstract
func setup(core: PECSCore)

@abstract
func run(event, value)

@icon("res://addons/note/texture/icon/effect_chain.svg")
@abstract
extends Node
class_name ChainNode

enum Response {
	DONE,
	WORKING
}

signal started(instance: RunInstance)
signal finished(instance: RunInstance)

class RunInstance extends RefCounted:
	var context = null
	var instance_time_scale: float = 1.0
	var in_physics: bool = false
	var instance_finished: bool = false
	var data: Dictionary = {}

@export_group("Misc")
## Overwrites ever checking _work, and just ends after _start.
## Recommended only for chain nodes that do everything in _start, and
## nothing in _work
@export var is_instant: bool = false

## If true, the chain's work method will be called as deferred.
## Not recommended for most effects, but can be useful for chain nodes
## that will modify physics properties or change level.
@export var defer_chain_work: bool = false

var active_instances: Array[RunInstance]

## Starts the chain node
func activate_chain(data, run_in_physics_process: bool = false, time_scale: float = 1.0) -> RunInstance:
	var new_instance = RunInstance.new()
	new_instance.instance_time_scale = time_scale
	new_instance.context = data
	new_instance.data = {}
	new_instance.in_physics = run_in_physics_process
	
	active_instances.append(new_instance)
	_chain_start(new_instance)
	started.emit(new_instance)
	return new_instance
	

func is_chain_running() -> bool:
	return !active_instances.is_empty()

@abstract
## VIRTUAL: Called when the chain node starts
func _chain_start(instance: RunInstance)
@abstract
## VIRTUAL: Called for each instance, ran in the process mode of the instance info.
func _chain_work(instance: RunInstance, delta: float) -> Response
## VIRTUAL: Called for each input event.
func _chain_input(instance: RunInstance, event: InputEvent) -> Response:
	return Response.WORKING
## VIRTUAL: Called when the chain node is done
func _chain_end(instance: RunInstance):
	pass

func __clean(inst: RunInstance):
	active_instances.erase(inst)
func __work(delta: float, i: RunInstance):
	var r = _chain_work(i, delta*i.instance_time_scale)
	if r == Response.DONE:
		i.instance_finished = true
		finished.emit(i)
		__clean.call_deferred(i)
func _process(delta: float) -> void:
	for i: RunInstance in active_instances:
		if i.instance_finished: continue
		if !i.in_physics:
			if defer_chain_work:
				__work.call_deferred(delta, i)
			else:
				__work(delta, i)
func _physics_process(delta: float) -> void:
	for i: RunInstance in active_instances:
		if i.instance_finished: continue
		if i.in_physics:
			if defer_chain_work:
				__work.call_deferred(delta, i)
			else:
				__work(delta, i)
func _input(event: InputEvent) -> void:
	for i: RunInstance in active_instances:
		var r = _chain_input(i, event)
		if r == Response.DONE:
			i.instance_finished = true

@icon("res://addons/note/texture/icon/effect_chain.svg")
@abstract
extends Node
class_name ChainNode

## A response return type to help organize the Chain Node flow.
enum Response {
	## If a chain method returns DONE, the chain node is to be marked as complete
	DONE,
	## If a chain method returns done, the chain node is to continue working.
	WORKING
}

## Emitted when a run instance is began, immediately after _chain_start is called.
signal started(instance: RunInstance)
## Emitted when a run instance is done, just before _chain_end.
signal finished(instance: RunInstance)
## Emitted after _chain_end is called, during deferred time, just before the instance
## is cleaned out from the chain node.
signal cleaned(instance: RunInstance)

class RunInstance extends RefCounted:
	var source: ChainNode
	## The target node or object that is provided as the context of the chain node.
	var context = null
	## Speeds up or slows down the runtime of the chain sequence.
	var instance_time_scale: float = 1.0
	## If true, runs in _physics_process
	var in_physics: bool = false
	## Internal variable, used to notify the chain node that work is done.
	var instance_finished: bool = false
	## Internal variable, marks an instance as cancelled for cleanup.
	var instance_cancelled: bool = false
	## Store data related to this run in this dictionary, so none of the data
	## influences other runs.
	var data: Dictionary = {}
	
	func cancel():
		instance_cancelled = true
		source._notify_cancelled(self)

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

## Starts the chain node. Pass in the relevant entity as context, like the node that triggered it.
func activate_chain(context, run_in_physics_process: bool = false, time_scale: float = 1.0) -> RunInstance:
	var new_instance = RunInstance.new()
	new_instance.source = self
	new_instance.instance_time_scale = time_scale
	new_instance.context = context
	new_instance.data = {}
	new_instance.in_physics = run_in_physics_process
	
	active_instances.append(new_instance)
	_chain_start(new_instance)
	started.emit(new_instance)
	return new_instance
	

func is_chain_running() -> bool:
	return !active_instances.is_empty()


func _notify_cancelled(instance: RunInstance):
	instance.instance_cancelled = true
	instance.instance_finished = true
	_chain_cancel(instance)
	__clean.call_deferred(instance)
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
## VIRTUAL: Called when the chain node must end prematurely
func _chain_cancel(instance: RunInstance):
	pass

func __clean(inst: RunInstance):
	cleaned.emit(inst)
	active_instances.erase(inst)
func __work(delta: float, i: RunInstance):
	var r = _chain_work(i, delta*i.instance_time_scale)
	if r == Response.DONE:
		i.instance_finished = true
		_chain_end(i)
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

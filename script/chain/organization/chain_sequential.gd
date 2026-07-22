@icon("res://addons/note/texture/icon/sequential_chain.svg")
extends ChainNode
class_name ChainSequence


## A sequence chain node, runs through each of its children one by one until every
## one of them has run in sequence.

## Optional, if assigned, chain nodes will be found through the children of this external node
## instead of the sequence's own children.
@export var external_sequence_root: Node

@export var output_debug_prints: bool = false

func _chain_print(i: RunInstance, message: String):
	if output_debug_prints or note.settings.note_info_prints:
		if i.in_physics:
			note.info("[b]PF#%d[/b] ) %s" % [Engine.get_physics_frames(), message], name)
		else:
			note.info("[b]F#%d[/b] ) %s" % [Engine.get_process_frames(), message], name)

func _chain_start(instance: RunInstance):
	var queue: Array[ChainNode] = []
	var root: Node
	if external_sequence_root == null or !is_instance_valid(external_sequence_root):
		root = self
	else:
		root = external_sequence_root
	
	for c in root.get_children():
		if c is ChainNode:
			queue.append(c)
	
	instance.data.set(&"sequence", queue)
	
	if queue.is_empty():
		instance.instance_finished = true
		return
	_chain_print(instance, "Beginning chain sequence with %d steps." % len(queue))
func _chain_cancel(instance: RunInstance):
	instance.data.set(&"sequence", [])
	var current: RunInstance = instance.data.get(&"awaiting", null)
	if current != null:
		current.cancel()
		_chain_print(instance, "Cancelled. Interrupted other chain node: %s" % current.source.name)
	else:
		_chain_print(instance, "Cancelled. No other nodes were interrupted.")
	
	instance.data.clear()
func _chain_work(instance: RunInstance, delta: float) -> Response:
	var queue: Array[ChainNode] = instance.data.get(&"sequence")
	
	while !queue.is_empty():
		var current: RunInstance = instance.data.get(&"awaiting", null)
		if current != null:
			if current.instance_finished:
				_chain_print(instance, "Finished step: %s." % queue[0].name)
				queue.pop_front()
				current = null
				instance.data.set(&"awaiting", null)
				continue
			else:
				break
		var item: ChainNode = queue[0]
		var new_instance = item.activate_chain(instance.context, instance.in_physics, instance.instance_time_scale)
		if item.is_instant:
			_chain_print(instance, "Step %s was started finished instantly." % queue[0].name)
			queue.pop_front()
			instance.data.set(&"awaiting", null)
			current = null
			continue
		else:
			_chain_print(instance, "Step %s has been started." % queue[0].name)
			instance.data.set(&"awaiting", new_instance)
			break
	
	if queue.is_empty():
		_chain_print(instance, "Sequence finished")
		return Response.DONE
	return Response.WORKING

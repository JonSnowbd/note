@icon("res://addons/note/texture/icon/sequential_chain.svg")
extends ChainNode
class_name ChainSequence


## A sequence chain node, runs through each of its children one by one until every
## one of them has run in sequence.

## Optional, if assigned, chain nodes will be found through the children of this external node
## instead of the sequence's own children.
@export var external_sequence_root: Node

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

func _chain_work(instance: RunInstance, delta: float) -> Response:
	var queue: Array[ChainNode] = instance.data.get(&"sequence")
	
	while !queue.is_empty():
		var current: RunInstance = instance.data.get(&"awaiting", null)
		if current != null:
			if current.instance_finished:
				queue.pop_front()
				current = null
				instance.data.set(&"awaiting", null)
				continue
			else:
				break
		var item: ChainNode = queue[0]
		var new_instance = item.activate_chain(instance.context, instance.in_physics, instance.instance_time_scale)
		if item.is_instant:
			queue.pop_front()
			instance.data.set(&"awaiting", null)
			current = null
			continue
		else:
			instance.data.set(&"awaiting", new_instance)
			break
	
	if queue.is_empty():
		return Response.DONE
	return Response.WORKING

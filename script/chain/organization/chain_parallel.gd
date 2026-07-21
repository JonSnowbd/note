@icon("res://addons/note/texture/icon/parallel_chain.svg")
extends ChainNode
class_name ChainParallel

## If true, the chain will work with no gaps between states finishing. By default(if false,)
## the next chain node is ran next frame.
@export var tight_chain: bool = false
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
				continue
			else:
				break
		var item: ChainNode = queue[0]
		instance.data.set(&"awaiting", item)
		break
	
	return Response.WORKING

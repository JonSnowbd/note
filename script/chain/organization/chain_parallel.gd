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
	var awaiting: Array[ChainNode.RunInstance] = []
	var root: Node
	if external_sequence_root == null or !is_instance_valid(external_sequence_root):
		root = self
	else:
		root = external_sequence_root
	
	for c in root.get_children():
		if c is ChainNode:
			queue.append(c)
			awaiting.append(c.activate_chain(instance.context))
	
	instance.data.set(&"sequence", queue)
	instance.data.set(&"awaiting", awaiting)
func _chain_cancel(instance: RunInstance):
	var awaiting: Array[RunInstance] = instance.data.get(&"awaiting", [])
	for inst in awaiting:
		inst.cancel()
	awaiting.clear()
	instance.data.set(&"awaiting", [])
func _chain_work(instance: RunInstance, delta: float) -> Response:
	var awaiting: Array[RunInstance] = instance.data.get(&"awaiting", [])
	var done: bool = true
	for inst in awaiting:
		if !inst.instance_finished:
			done = false
			break
	return Response.DONE if done else Response.WORKING

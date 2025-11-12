@icon("res://addons/note/texture/icon/parallel_chain.svg")
extends ChainNode
class_name ChainNodeParallel

## This chain node will immediately(or in a staggered fashion) run every child
## chain node, and return done when they are all finished.

## If true, nodes are requeried on start, providing an up to date
## list of nodes and their order each time. Not needed if you are sure the
## hierarchy will be static.
@export var requery_nodes_on_start: bool = true
## If >0.0 then each task will be started one after the other at this pace
## in seconds.
@export var stagger: float = 0.0
## If >0.0 then this parallel chain will be forced as finished after this amount
## of time. Note stagger takes precedence, if you are forcing a duration of 1 second,
## but would take 2s to activate every node, this chain node will last 2s.
@export var force_duration: float = 0.0

var running: bool = false
var internal_data = null
var nodes: Array[ChainNode] = []
var cooldown: float = 0.0
var current_index: int = 0
var lifetime: float = 0.0

func _ready() -> void:
	nodes = []
	if !requery_nodes_on_start:
		for c in get_children():
			if c is ChainNode:
				nodes.append(c)
	super()

func _advance(delta: float):
	lifetime += delta
	if stagger > 0.0:
		if cooldown > 0.0:
			cooldown -= delta
			if cooldown <= 0.0:
				if current_index < len(nodes):
					nodes[current_index]._start(internal_data)
				current_index += 1
				cooldown = stagger

func _check_done():
	if !running:
		return
	if stagger > 0.0:
		if current_index < len(nodes):
			return
	if force_duration > 0.0:
		if lifetime >= force_duration: # Exit out when expired
			running = false
			return
	for i in nodes:
		if !i._done():
			return
	running = false

func _process(delta: float) -> void:
	if running and runtime == 1:
		_advance(delta*time_scale)
		_check_done()
func _physics_process(delta: float) -> void:
	if running and runtime == 0:
		_advance(delta*time_scale)
		_check_done()

func _start(data):
	lifetime = 0.0
	internal_data = data
	current_index = 0
	if requery_nodes_on_start:
		nodes.clear()
		for c in get_children():
			if c is ChainNode:
				nodes.append(c)
	running = true
	if stagger <= 0.0:
		for c in nodes:
			c._start(internal_data)
	else:
		nodes[0]._start(internal_data)
		current_index = 1
		cooldown = stagger
	on_start.emit()

func _done() -> bool:
	if !running:
		return true
	return false

@icon("res://addons/note/texture/icon/sequential_chain.svg")
extends NoteChainNode
class_name NoteChainSequence

## This chain node will start and wait for each node in sequence,
## each its children. Provided they are a NoteChainNode or NoteChainEffect.

## If true, nodes are requeried on start, providing an up to date
## list of nodes and their order each time. Not needed if you are sure the
## hierarchy will be static.
@export var requery_nodes_on_start: bool = true
## The cooldown between steps (after each step is done, not individual work ticks)
@export var time_between_steps: float = 0.0
## How long after start before iterating
@export var padding_start: float = 0.0
## How long after being done, before finishing
@export var padding_end: float = 0.0

var running: bool = false
var internal_data = null
var current_index: int = -1
var nodes: Array[NoteChainNode] = []
var cooldown: float = 0.0

var awaiting_cooldown: bool = false

func _ready() -> void:
	nodes = []
	if !requery_nodes_on_start:
		for c in get_children():
			if c is NoteChainNode:
				nodes.append(c)
	super()
func _process(delta: float) -> void:
	delta *= time_scale
	if runtime == 1 and cooldown >= 0.0:
		cooldown -= delta
	if running and cooldown <= 0.0 and runtime == 1:
		_iterate(delta)
func _physics_process(delta: float) -> void:
	delta *= time_scale
	if runtime == 0 and cooldown >= 0.0:
		cooldown -= delta
	if running and cooldown <= 0.0 and runtime == 0:
		_iterate(delta)

func _iterate(delta: float):
	## If -1, then we need to initialize the first child
	if current_index == -1:
		var first_child = nodes[0]
		first_child._start(internal_data)
		print("Starting first: "+first_child.name)
		current_index = 0
	var current_child: NoteChainNode = nodes[current_index]
	if awaiting_cooldown:
		current_child._start(internal_data)
		awaiting_cooldown = false
	var next_exists: bool = current_index+1 < len(nodes)
	if current_child._done():
		if next_exists:
			current_index = current_index+1
			if time_between_steps > 0.0:
				cooldown = time_between_steps
				awaiting_cooldown = true
				return
			var next = nodes[current_index]
			print("Starting next: "+next.name)
			next._start(internal_data)
		else:
			if padding_end > 0.0:
				print("Delaying end")
				cooldown = padding_end
				return
			else:
				print("Ending")
				on_finish.emit()
				running = false
				return

func _start(data):
	internal_data = data
	current_index = -1
	if requery_nodes_on_start:
		nodes.clear()
		for c in get_children():
			if c is NoteChainNode:
				nodes.append(c)
	running = true
	cooldown = padding_start
	on_start.emit()

func _done() -> bool:
	if !running:
		return true
	return false

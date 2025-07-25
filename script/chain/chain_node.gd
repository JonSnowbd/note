extends Node
class_name ChainNode

signal on_start
signal on_finish

## If runtime == 0, run in physics, runtime == 1 runs in process
@export_enum("Physics Process", "Process") var runtime: int
@export var auto_start: bool = false
@export var auto_start_data: Node
@export var time_scale: float = 1.0
@export var data_override: Node

func _ready() -> void:
	if auto_start:
		begin_chain(auto_start_data)

## Starts the chain node
func begin_chain(data):
	_start(data)
func end_chain():
	_clean()

## Virtual: this is called to begin a chain node
func _start(data):
	pass
## Virtual: This is called to interrupt and stop.
func _clean():
	pass
## Virtual: This is called to ask if this chain node is done its work.
func _done() -> bool:
	return true

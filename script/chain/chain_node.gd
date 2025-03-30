extends Node
class_name NoteChainNode

signal on_start
signal on_finish

@export_enum("Physics Process", "Process") var runtime: int
@export var auto_start: bool = false
@export var auto_start_data: Node
@export var time_scale: float = 1.0

func _ready() -> void:
	if auto_start:
		begin_chain(auto_start_data)

func begin_chain(data):
	_start(data)
func end_chain():
	_clean()

## Virtual this is called to begin a chain node
func _start(data):
	pass
func _clean():
	pass
## Virtual
func _done() -> bool:
	return true

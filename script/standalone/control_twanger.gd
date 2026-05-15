extends Node
class_name ControlTwanger

@export var trigger_on_spawn: Array[Callable]

## Uses visual mods to certain actions on the parent.

var current_tween: Tween
var muxers: Array[Callable]

func send_tween(t: Tween):
	if current_tween != null and current_tween.is_running():
		current_tween.pause()
		while current_tween.custom_step(1.0): pass
## Sends a muxer, if duration is given,
func send_muxer(c: Callable, duration: float = -1.0):
	muxers.append(c)


func _hover_changed(old, new):
	pass
func _work(delta: float):
	for m in muxers:
		m.call(delta, self)

func _ready() -> void:
	note.controls.hovered_node_changed.connect(_hover_changed)
func _process(delta: float) -> void:
	if (current_tween != null and current_tween.is_running()) or len(muxers) > 0:
		_work(delta)

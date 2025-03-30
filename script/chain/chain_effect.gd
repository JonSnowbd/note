@icon("res://addons/note/texture/icon/effect_chain.svg")
extends NoteChainNode
class_name NoteChainEffect

## Virtual this is called to begin a chain node
func _start(data):
	pass
## Virtual this is called when cancelled, to clean up earlier than expected.
func _clean():
	pass
## Virtual this is called to query if the node is finished. Return true if finished.
func _done() -> bool:
	return true

@icon("res://addons/note/texture/icon/mvu/fragment.svg")
extends Node
class_name NoteAppFragment

signal triggered_event(event_name: String, arguments: Array)

## If assigned, fragment can take and place children into a specific node.
@export var inner_socket: NoteAppSocket
## If true, props will be passed to the fragment script as a set call in addition
## to an update call.
@export var attempt_to_forward_props: bool = false

func fragment_init(shell: NoteAppShell):
	pass
func fragment_update(shell: NoteAppShell, props: Dictionary[StringName,Variant]):
	pass

func raise_event(event: StringName, arguments: Array = []):
	triggered_event.emit(event, arguments)

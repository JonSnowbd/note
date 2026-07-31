@icon("res://addons/note/texture/icon/mvu/fragment.svg")
extends Node
class_name NoteAppFragment

signal triggered_event(event_name: String, arguments: Array)

## If assigned, fragment can take and place children into a specific node.
@export var inner_socket: NoteAppSocket
## If true, props will be passed to the fragment script as a set call in addition
## to an update call.
@export var attempt_to_forward_props: bool = false


## TODO: implement focus for vmu
@export_group("Focus Settings")
## If true, focus will target this with a drill-in option, for containers that
## need to be clicked in order to focus on their children. If false, the children
## will be instantly focusable from neighbouring nodes.
@export var gateway_to_children: bool = false
## If true, this will be quick selectable with the select button to cycle between
## major elements, and will be a candidate for default focus
@export var major_focus: bool = false

func fragment_init(shell: NoteAppShell):
	pass
func fragment_update(shell: NoteAppShell, props: Dictionary[StringName,Variant]):
	pass
func fragment_post_update(shell: NoteAppShell, self_node: NoteAppShell.ShellNode):
	pass

func raise_event(event: StringName, arguments: Array = []):
	triggered_event.emit(event, arguments)

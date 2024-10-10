@icon("res://addons/note/texture/icon/state.svg")
extends Node
class_name NoteState

@export var aliases: Array[String]
var machine: NoteStateMachine
var original_process_mode: Node.ProcessMode
var state_active: bool = false

## Virtual
func state_enter(from: NoteState, data = null):
	pass
## Virtual
func state_leave(to: NoteState):
	pass
func transition(to: NoteState, data = null):
	machine.transition_to(to, data)

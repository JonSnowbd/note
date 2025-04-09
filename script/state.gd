@icon("res://addons/note/texture/icon/state.svg")
extends Node
class_name NoteState

## A list of strings that will be added as identities that point to this state,
## in the machine. This is only used for machine.transition_to_named
@export var aliases: Array[String]
var machine: NoteStateMachine
var original_process_mode: Node.ProcessMode

## Virtual
func state_enter(from: NoteState, data = null):
	pass
## Virtual
func state_leave(to: NoteState):
	pass

## Quality of life call to make the machine transition to a new state. 
## Equivalent to [code]machine.transition_to(to, data)[/code]
func transition(to: NoteState, data = null):
	machine.transition_to(to, data)

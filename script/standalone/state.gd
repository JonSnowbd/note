@icon("res://addons/note/texture/icon/state.svg")
extends Node
class_name State

## A list of strings that will be added as identities that point to this state,
## in the machine. This is only used for machine.transition_to_named
@export var aliases: Array[String]
var machine: StateMachine
var original_process_mode: Node.ProcessMode

## VIRTUAL: Called when this state is entered, after the last
## one was left.
func state_enter(from: State, data = null):
	pass
## VIRTUAL: Called when the state is left, and before the next
## one is began.
func state_leave(to: State):
	pass

## Quality of life call to make the machine transition to a new state. 
## Equivalent to [code]machine.transition_to(to, data)[/code]
func transition(to: State, data = null):
	machine.transition_to(to, data)
## Returns to the machines initial state.
func return_to_default_state():
	transition(machine.initial_state)

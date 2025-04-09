@icon("res://addons/note/texture/icon/state_machine.svg")
extends Node
class_name NoteStateMachine

## This is a state machine that doesnt use a trait or interface for state updating/processing/input.
## Instead if a state is active it is enabled by godot's process mode on the node, so each state
## can intuitively use _unhandled_input, _process, as you'd expect, rather than virtual methods.

## This is the player, or object that each state will operate on.
@export var context: Node
## This state will be the starting state. It should be a child of this machine.
@export var initial_state: NoteState
## If true, state changes and other info will be logged.
@export var debug: bool = false

var current_state: NoteState = null
var owned_states: Array[NoteState] = []
var alias_dictionary: Dictionary = {}

func _ready() -> void:
	if initial_state != null:
		transition_to(initial_state)
func _enter_tree() -> void:
	for c in get_children():
		if c is NoteState:
			introduce_state(c)
## Takes a state object, and adds it to the state machine's internal state list,
## and claims ownership of the node if it is not already owned by this machine.
func introduce_state(state:NoteState):
	if !owned_states.has(state):
		if debug:
			note.info(name+" state machine has added a new state: "+state.name)
		state.machine = self
		state.original_process_mode = state.process_mode
		state.process_mode = Node.PROCESS_MODE_DISABLED
		if state.get_parent() != self:
			if debug:
				note.info(name+" state machine has re-parented a node to exist under itself instead: "+state.name)
			state.get_parent().remove_child(state)
			add_child(state)
		owned_states.append(state)
		if alias_dictionary.has(state.name):
			note.warn("Potential state machine state name/alias clash: "+state.name)
		alias_dictionary[state.name] = state
		for alias in state.aliases:
			alias_dictionary[alias] = state
	else:
		if debug:
			note.info(name+" state machine has gone over a state that was already added: "+state.name)

## Transitions to a new state by node reference. Data can be passed as transition context, for example falling -> grounded
## can pass the velocity of the impact for the new state to handle stuff like falling damage. next_state can be null, to
## disable the state machine.
func transition_to(next_state: NoteState, data = null):
	var previous_state: NoteState = current_state
	if current_state != null:
		current_state.state_leave(next_state)
		if debug:
			note.info(name+" state machine has told "+current_state.name+" to exit")
		current_state.process_mode = Node.PROCESS_MODE_DISABLED
	current_state = next_state
	if current_state != null:
		current_state.state_enter(previous_state, data)
		if debug:
			note.info(name+" state machine has told "+current_state.name+" to enter")
		current_state.process_mode = current_state.original_process_mode
	else:
		if debug:
			note.info(name+" state machine is now not processing a state.")

## Looks up all state aliases, and node names, and transitions to the node it finds.
func transition_to_named(state_name: String, data = null):
	if alias_dictionary.has(state_name):
		transition_to(alias_dictionary[state_name], data)
		return
	for child in get_children():
		if child.name == state_name and child is NoteState:
			transition_to(child, data)
			return
	note.warn("Failed to find and transition to alias/name: "+state_name)

## Stops all states, same as `transition_to(null)`
func stop():
	transition_to(null)

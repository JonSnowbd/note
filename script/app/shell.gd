@icon("res://addons/note/texture/icon/mvu/shell.svg")
@abstract
extends Node
class_name NoteAppShell

signal event_raised(event: Event)

## Helper for godot's stricter type checking re: dictionary and array subtypes
const NoProps: Dictionary[StringName,Variant] = {}

class Event extends RefCounted:
	var app_shell: NoteAppShell
	var source_fragment: NoteAppFragment = null
	var source_node: ShellNode = null
	var event_name: StringName
	var arguments: Array = []
	func relayout():
		if app_shell != null:
			app_shell.trigger_relayout()
		elif source_node != null and source_node.shell != null:
			source_node.shell.trigger_relayout()

class ShellNode extends RefCounted:
	var key: StringName = &""
	var parent: ShellNode = null
	var source: PackedScene = null
	var children: Array[ShellNode] = []
	var props: Dictionary[StringName,Variant] = {}
	var reactions: Dictionary[StringName,Callable] = {}
	var instantiated_node: Node = null
	var root_fragment: NoteAppFragment = null
	var shell: NoteAppShell
	var hydrated: bool = false
	
	## Generates a shell node from generic data, this could be a PackedScene,
	## a string, or another ShellNode for a deep copy.
	static func from_data(user_data, shell: NoteAppShell) -> ShellNode:
		var root:ShellNode = ShellNode.new()
		root.reactions = {}
		if user_data is ShellNode:
			root.parent = user_data.parent
			root.source = user_data.source
			root.children = []
			root.children.append_array(user_data.children)
			root.props = {}
			root.props.merge(user_data.props)
			root.reactions = user_data.reactions
		elif user_data is PackedScene:
			root.source = user_data
		elif user_data is String:
			root.source = note.loading_screen.force_fetch(user_data)
		root.hydrated = false
		root.shell = shell
		return root
	
	## Chain method quality of life. Adds an event reaction and returns self for other calls.
	func on(event_name: StringName, reaction: Callable) -> ShellNode:
		reactions[event_name] = reaction
		return self
	## Chain method quality of life. Sets props and returns self for other calls.
	func with_props(new_props: Dictionary[StringName,Variant]) -> ShellNode:
		props = new_props
		return self
	## Chain method quality of life. Sets children and returns self for other calls.
	func with_children(child_pieces: Array) -> ShellNode:
		children = []
		for i in child_pieces:
			var new_child = ShellNode.from_data(i, shell)
			new_child.parent = self
			children.append(new_child)
		return self
	## Chain method quality of life. Sets key and returns self for other calls.
	func with_key(user_key: StringName):
		key = user_key
		return self
	## Deletes instantiated self created things, including children. Called internally.
	func destroy():
		if instantiated_node != null:
			if instantiated_node.get_parent() != null:
				instantiated_node.get_parent().remove_child(instantiated_node)
			instantiated_node.queue_free()
		for c in children:
			if c.instantiated_node != null:
				c.instantiated_node.queue_free()
		instantiated_node = null
		children = []
		hydrated = false
	
	## Reacts to differences and updates self state to be equal to other.
	func diff(other: ShellNode):
		# If sources are different, its fundamentally un-redeemable, start from scratch starting
		# here.
		if source != other.source:
			if shell.transition_root_changes and parent == null:
				note.transition.trigger(0.5)
			destroy()
			source = other.source
			hydrate()
		
		props.clear()
		props.merge(other.props)
		reactions.clear()
		reactions.merge(other.reactions)
		## TODO: Use keys to reorder before anything else
		
		# Diff the children that exist currently, so if we had 2 children and other has 3,
		# we .diff our 2 children against other's first 2 children. If we had 3 and other has 1,
		# we .diff our 1 child against other's first child.
		for i in range(len(children)):
			if i < len(other.children):
				children[i].diff(other.children[i])
		
		# Then we record where other's additional children begin, and copy them over.
		var extra_children = other.children.slice(max(len(children), 0))
		while len(children) < len(other.children):
			var new_child = ShellNode.from_data(extra_children.pop_front(), shell)
			new_child.parent = self
			if new_child.root_fragment != null:
				new_child.root_fragment.fragment_update(shell, new_child.props)
			children.append(new_child)
			if hydrated:
				new_child.hydrate()
		
		# And finally we delete from the back any children that don't exist in
		# other.
		while len(children) > len(other.children):
			var node: ShellNode = children.pop_back()
			node.destroy()
		
		# Update fragment.
		if root_fragment != null:
			root_fragment.fragment_update(shell, props)

	## Called internally when we need to ensure that the virtual node exists in the tree,
	## and all of its children.
	func hydrate():
		if !hydrated:
			# Instance from the source
			instantiated_node = source.instantiate()
			for c in instantiated_node.get_children():
				if c is NoteAppFragment:
					root_fragment = c
					root_fragment.triggered_event.connect(shell._raised_event.bind(root_fragment, self))
					root_fragment.fragment_init(shell)
					root_fragment.fragment_update(shell, props)
					break
			
			# If parent is null, this is a root shell node, and must be added
			# to the shell's root node.
			if parent == null:
				if shell.root_socket != null:
					shell.root_socket.get_parent().add_child(instantiated_node)
			else:
				# Otherwise, we probe for the parent's root fragment.
				if parent.root_fragment != null:
					if parent.root_fragment.inner_socket != null:
						parent.root_fragment.inner_socket.get_parent().add_child(instantiated_node)
			hydrated = true
		
		# Even if hydrated, its good to trigger an update here.
		if root_fragment != null:
			root_fragment.fragment_update(shell, props)
			if root_fragment.attempt_to_forward_props:
				for k in props.keys():
					root_fragment.set(k, props[k])
		
		# Then triple check that all the children are hydrated, and parented to the correct node.
		for c in children:
			c.parent = self
			c.hydrate()

	## Takes all the children and then sorts them, so that the order of children starts just
	## below the socket, and then descends down the children. This is called for you internally.
	func sort_children():
		if root_fragment == null or root_fragment.inner_socket == null or children.is_empty(): return
		var target_root = root_fragment.inner_socket.get_parent()
		var previous = root_fragment.inner_socket
		for i in range(len(children)):
			target_root.move_child(children[i].instantiated_node, previous.get_index()+1)
			previous = children[i].instantiated_node

@export var root_node: Node
@export var root_socket: NoteAppSocket
## If assigned, this node will be the root for floating controls
@export var floating_root: Node
## When the root node changes, trigger a note transition. Recommended only for
## uses of shell that covers the whole screen, such as applications.
@export var transition_root_changes: bool = false

var _current_tree: ShellNode = null
var _shell_fragments: Array[NoteAppFragment] = []
var _updating: bool = false

func _hookup(node: Node):
	if node is NoteAppFragment:
		node.fragment_init(self)
		node.fragment_update(self, NoProps)
		_shell_fragments.append(node as NoteAppFragment)
	for c in node.get_children():
		_hookup(c)
func _ready() -> void:
	initialize()
	_hookup(root_node)
	_updating = true
	view()


func _raised_event(event_name: StringName, event_args: Array, fragment: NoteAppFragment, node: ShellNode):
	var evt = Event.new()
	evt.app_shell = self
	evt.event_name = event_name
	evt.source_fragment = fragment
	evt.source_node = node
	evt.arguments = event_args
	if node.reactions.has(event_name):
		node.reactions[event_name].call(evt)
	event_raised.emit(evt)


## Called when everything is good to go.
@abstract
func initialize()


## This is the update function that calls layout to put together
## the shell's controls.
@abstract
func view()


func layout(layout_data):
	var proposition: ShellNode = ShellNode.from_data(layout_data, self)
	## Handle root changes
	if _current_tree == null and proposition != null:
		if transition_root_changes:
			note.transition.trigger(0.5)
		_current_tree = proposition
		_current_tree.hydrate()
		_current_tree.sort_children()
	elif _current_tree != null and proposition == null:
		if transition_root_changes:
			note.transition.trigger(0.5)
		_current_tree.destroy()
		_current_tree = null
	
	elif _current_tree != null and proposition != null:
		_current_tree.diff(proposition)
		_current_tree.hydrate()
		_current_tree.sort_children()
	
	for piece in _shell_fragments:
		piece.fragment_update(self, NoProps)

## Quick way to start the chain methods, simple shell node constructor.
func with(prefab) -> ShellNode:
	return ShellNode.from_data(prefab, self)
func with_props(prefab, props: Dictionary[StringName,Variant] = {}) -> ShellNode:
	return ShellNode.from_data(prefab, self).with_props(props)
## Shortcut to define a fragment with embedded children.
func with_children(prefab, children: Array = []) -> ShellNode:
	return ShellNode.from_data(prefab, self).with_children(children)

## Creates an array of nodes using prefab as the base, and passing each item as a prop to each instance.
func quick_map(prefab, items: Array = [], prop_name: StringName = &"value") -> Array[ShellNode]:
	var children: Array[ShellNode] = []
	for i in items:
		children.append(ShellNode.from_data(prefab, self).with_props({prop_name: i}))
	return children

## Shorthand for creating a generic Godot button with the pressed event already hooked up to
## the given event.
func quick_btn(label: String, on_press: Callable) -> ShellNode:
	return (
		ShellNode.from_data("uid://d2eorjxlt1q4l", self)
		.with_props({&"text": label})
		.on(&"pressed", on_press)
	)

## Dummy arguments do nothing, they are for signal compatibility.
func trigger_relayout(_dummy1 = null, _dummy2 = null, _dummy3 = null, _dummy4 = null, _dummy5 = null, _dummy6 = null):
	view()

## Triggers a re-layout every time the provided signal goes off.
func add_relayout_trigger(relayout_signal: Signal):
	relayout_signal.connect(trigger_relayout)

func process_floating(delta: float, control: Control):
	control.position.x -= 60.0*delta

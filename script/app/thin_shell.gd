extends NoteAppShell
class_name NoteAppThinShell

## Like a shell but instead of deriving the class, you can point at a node and
## the name of its view function.

@export var source_node: Node
@export var source_function: StringName

func initialize():
	pass

func view():
	if source_node != null and !source_function.is_empty() and source_node.has_method(source_function):
		source_node.call(source_function, self)

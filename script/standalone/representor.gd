@abstract
extends Control
class_name Representor

## Defines a widget that can represent a specific type. For example an Item widget
## that can display the items icon, name, and description generically.

static func show_tooltip(value, representor_uid: String):
	note.tooltip.request_string(representor_uid, value)

@abstract
func represent(value)

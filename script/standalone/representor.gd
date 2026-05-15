@abstract
extends Control
class_name Representor

static func tooltip(value, representor_uid: String):
	note.tooltip.request_string(representor_uid, value)

@abstract
func represent(value)

extends Node
class_name Presenter

## Works with a control node to present a data structures Representor via
## get()

## The variable name inside the parent that is checked, basically set this to what
## you'd give to [code]get_parent().get(/here/)[/code]
@export var target_variable_name: StringName
## The uid/path of the representor that will pop up in a tooltip.
@export_file("*.tscn", "*.scn") var representor_prefab: String
## Optional, set this to override what node gets checked for hover/data.
@export var source_override: Control

var _current_source: Control
func get_source() -> Control:
	if source_override != null: return source_override
	return get_parent() as Control

func _enter_tree() -> void:
	_current_source = get_source()

func _physics_process(delta: float) -> void:
	if note.controls.hovered_node == _current_source and _current_source != null:
		var value = _current_source.get(target_variable_name)
		if value != null:
			note.tooltip.request_string(representor_prefab, value)

@tool
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	if object == null: return false
	return object.has_method("note_property_editor")

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if object.has_method("note_property_editor"):
		var editor = object.note_property_editor(name) as GDScript
		if editor != null:
			var inst = editor.new()
			add_property_editor(name, inst)
			return true
	return false

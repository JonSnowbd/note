@tool
extends Resource
class_name NoteAppLibraryEntry


@export var frag_name: StringName = &"" :
	set(val):
		frag_name = val
		emit_changed()
@export_multiline var frag_description: String = ""
@export var can_contain_children: bool = false :
	set(val):
		can_contain_children = val
		emit_changed()

@export_group("Required References")
@export var frag_scene: PackedScene = null :
	set(val):
		frag_scene = val
		emit_changed()
@export var frag_script: GDScript = null :
	set(val):
		frag_script = val
		emit_changed()

@export_group("State Setup")
@export var props: Dictionary[StringName, Variant] = {} :
	set(val):
		props = val
		emit_changed()
@export var events: Array[StringName] = [] :
	set(val):
		events = val
		emit_changed()
@export var flags: Array[StringName] = [] :
	set(val):
		flags = val
		emit_changed()
@export_group("", "")
@export_tool_button("Register / Rebuild Library") var _build = _rebuild

func _rebuild():
	if !Engine.is_editor_hint(): return
	var settings: String = ProjectSettings.get_setting("addons/note/settings", "")
	if !settings.is_empty():
		var file: NoteDeveloperSettings = load(settings)
		if !file.user_fragments.has(self):
			print_rich("[color=#999999FF]Registering %s to Note VMU Library" % resource_path)
			file.user_fragments.append(self)
		file.__regenerate_library()

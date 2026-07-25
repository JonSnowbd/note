@tool
extends Resource
class_name NoteAppLibraryEntry


@export var frag_name: StringName = &""
@export_multiline var frag_description: String = ""
@export var can_contain_children: bool = false

@export_group("Required References")
@export var frag_scene: PackedScene = null
@export var frag_script: GDScript = null

@export_group("State Setup")
@export var props: Dictionary[StringName, Variant] = {}
@export var events: Array[StringName] = []
@export var flags: Array[StringName] = []
@export_group("", "")
@export_tool_button("Update Library Build") var _build = _rebuild

func _rebuild():
	if !Engine.is_editor_hint(): return
	var settings: String = ProjectSettings.get_setting("addons/note/settings", "")
	if !settings.is_empty():
		var file: NoteDeveloperSettings = load(settings)
		file.regenerate_library()

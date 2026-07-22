@tool
extends Resource
class_name NoteAppLibraryEntry

@export var frag_name: StringName = &""
@export_multiline var frag_description: String = ""
@export var can_contain_children: bool = false
@export var frag_scene: PackedScene = null
@export var frag_script: GDScript = null
@export var props: Dictionary[StringName, Variant] = {}
@export var events: Array[StringName] = []

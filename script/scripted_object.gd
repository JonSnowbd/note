extends Resource
class_name ScriptedObject

const MetaTag_ID = "scripted_object_meta"
const MetaTag_ObjectRef = "scripted_object_resource_reference"
const MetaTag_Redirection = "scripted_object_redirection"

@export_group("References", "scripted_object_")
## Required
@export var scripted_object_name: String
@export_multiline var scripted_object_description: String
## Required
@export var scripted_object_version: int
## Optional, lets the scripted object exist in the world.
@export var scripted_object_base: PackedScene
## Optional, a reference for the script of the object.
@export var scripted_object_script: Script
@export_group("Settings", "scripted_object_")
## If true, the scripted object is injected with a unique ID via the meta
## godot system.
@export var scripted_object_generate_id: bool = true

static func push_tooltip(object: Node):
	var scripted_object: ScriptedObject = object.get_meta(MetaTag_ObjectRef) as ScriptedObject
	if scripted_object != null:
		note.tooltip.request_simple(scripted_object.scripted_object_name, scripted_object.scripted_object_description)
static func get_object_info(object: Node) -> ScriptedObject:
	return object.get_meta(MetaTag_ObjectRef) as ScriptedObject
static func encode(object: Node) -> String:
	var scripted_object: ScriptedObject = object.get_meta(MetaTag_ObjectRef) as ScriptedObject
	if scripted_object == null:
		push_error("Object '%s' was not created via a scripted object." % object.name)
		return ""
	var dict = {}
	if object.has_meta(MetaTag_Redirection):
		dict["redirected_resource"] = object.get_meta(MetaTag_Redirection)
	dict["user_data"] = {}
	if object.has_method("scriptable_encode"):
		object.scriptable_encode(dict["user_data"])
	else:
		push_warning("Object '%s' does not have a `scriptable_encode(in_data: Dictionary)` method")
	dict["scripted_object_path"] = scripted_object.resource_path
	if scripted_object.scripted_object_generate_id:
		dict["scripted_object_id"] = object.get_meta(MetaTag_ID)
	return JSON.stringify(dict)
## Takes a string made via `ScriptedObject.encode(obj)` and hydrates it into its full object.
static func decode(data: String) -> Node:
	var decoded_data: Dictionary = JSON.parse_string(data)
	var scripted_object: ScriptedObject = load(decoded_data["scripted_object_path"]) as ScriptedObject
	
	
	var object: Node
	if decoded_data.has(""):
		object = scripted_object.create_object(load(decoded_data["redirected_resource"]))
	else:
		object = scripted_object.create_object()
	object.set_meta(MetaTag_ID, decoded_data["scripted_object_id"])
	if object.has_method("scriptable_decode"):
		object.scriptable_decode(decoded_data["user_data"])
	else:
		push_warning("Object '%s' does not have a `scriptable_decode(data: Dictionary)` method")
	return null

## Creates a direct instance of the base script, and assigns the standard
## scripted object meta properties.
func instance_script() -> Node:
	var new_object = scripted_object_script.new()
	if scripted_object_generate_id:
		new_object.set_meta(MetaTag_ID, UUID.v4())
	new_object.set_meta(MetaTag_ObjectRef, self)
	new_object.add_to_group("ScriptedObjectInstance")
	return new_object
func create_object(redirected_scene: PackedScene = null) -> Node:
	if scripted_object_base == null and redirected_scene == null:
		return null
	var base = scripted_object_base
	if redirected_scene != null:
		base = redirected_scene
	var new_object = base.instantiate()
	if redirected_scene != null:
		base.set_meta(MetaTag_Redirection, redirected_scene.resource_path)
	if scripted_object_generate_id:
		new_object.set_meta(MetaTag_ID, UUID.v4())
	new_object.set_meta(MetaTag_ObjectRef, self)
	new_object.add_to_group("ScriptedObjectInstance")
	return new_object

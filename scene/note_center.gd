extends Node

## Called [b]after[/b] a save is loaded.
signal save_loaded
## Called [b]after[/b] a save is unloaded.
signal save_unloaded

const TypeLoadingScreen = preload("uid://dj5ae4svel0vv")
const TypeControlGuide = preload("uid://b5urykf5xl2tp")
const TypeNotifications = preload("uid://bd2xr6domuqt7")
const TypePhaseManager = preload("uid://caty0hb5uijx2")
const TypeTooltipManager = preload("uid://ej2vfmjw2dkq")
const TypeUtil = preload("uid://bqvtnaowd8lta")
const TypeTransitionManager = preload("uid://b53sh8bwtjj8g")
const TypeLevelManager = preload("uid://d1ghq77fsfx07")
const TypeControlManager = preload("uid://dsuqhn7s348wn")
const TypeMetadata = preload("uid://dpj8fxiopchxi")
const TypeFocusGroup = preload("uid://4iwdim3cbvkf")
const TypeUI = preload("uid://dqm1jcqmseeun")
const _default_note_tests = [
	"uid://df1tif6bomrwk"
]

@export_group("Internal References")
@export var level: TypeLevelManager
@export var controls: TypeControlManager
@export var notifications: TypeNotifications
@export var loading_screen: TypeLoadingScreen
@export var transition: TypeTransitionManager
@export var control_guide: TypeControlGuide
@export var tooltip: TypeTooltipManager
@export var phase: TypePhaseManager
@export var focus: TypeFocusGroup
@export var util: TypeUtil
@export var ui: TypeUI

## This is the Note Dev Settings that you provide via your project settings.
## Do not edit this during runtime with the intention of it being saved!
var settings: NoteDeveloperSettings
## This is the currently loaded save, it can be null before a load.
var save: NoteSaveSession = null

var storage: Dictionary = {}
var meta: TypeMetadata

func _init() -> void:
	var settings_path: String = ProjectSettings.get_setting("addons/note/settings", "")
	if settings_path.is_empty():
		error("Settings path was not set in project settings: Addons/Note/Settings")
		return
	else:
		settings = load(settings_path)
	
func _ready() -> void:
	if settings.test_mode:
		return
	meta = TypeMetadata.new()
	if settings.save_soft_settings:
		meta.restore_soft_settings(self)
func _notification(what: int) -> void:
	if settings.test_mode:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		end_session()
		meta.persist(self)
func _process(delta: float) -> void:
	if save != null:
		var timer = storage.get_or_add("save_session_timer", 0.0)
		timer += delta
		
		if timer > settings.save_pulse_duration:
			timer -= settings.save_pulse_duration
			save.pulse(settings.save_pulse_duration)
		
		storage["save_session_timer"] = timer
func _input(event: InputEvent) -> void:
	if settings != null and !settings.run_tests_action.is_empty():
		if event.is_action_pressed(settings.run_tests_action):
			run_tests()

func run_tests(exit_after: bool = false):
	var tests = settings.tests
	if settings.include_note_tests:
		tests.append_array(_default_note_tests)
	for test in tests:
		await get_tree().process_frame
		var current_test = await level.change_to(test) as NoteTestFixture
		await current_test.test_over
	if exit_after:
		get_tree().quit()
	else:
		level.change_to(settings.initial_scene)

func _message(header: String, separator: String = " >> ", message: String = ""):
	var time: float = float(Time.get_ticks_msec()) / 1000.0
	print_rich("[b][color=grey]"+util.seconds_to_speedrun_stamp(time)+"[/color][/b] "+header+separator+message)
func info(message: String, header: String = "Note"):
	_message(header, " >> ", message)
func warn(message: String, header: String = "Note"):
	_message("[color=yellow]"+header, " !! ", message)
func stack_trace(message: String):
	_message("[color=cyan]STCK", " >> ", message)
	var stack = get_stack()
	var count = 1
	for line in stack:
		if line == stack[0]: continue # The first is always this function, so skip it
		var msg = "%s:%d -> %s()" % [line["source"], line["line"], line["function"]]
		_message("[color=cyan]#%3d" % count, " >> ", msg)
		count += 1
func error(message: String):
	_message("[color=red]ERR ", " !! ", message)
	var stack = get_stack()
	for line in stack:
		var msg = "%s:%d -> %s()" % [line["source"], line["line"], line["function"]]
		_message("[color=red]STACK", " >> ", msg)

## Use this to time a function or portion of your app, call once with a string parameter
## to name what you're timing, and call again with no parameters to end the timer and log.
func time(header: String = ""):
	if !storage.has("note_timing_data"):
		storage["note_timing_data"] = {
			"header_stack" = [],
			"time_stack" = [],
		}
	
	var head_array: Array = storage["note_timing_data"]["header_stack"]
	var time_array: Array = storage["note_timing_data"]["time_stack"]
	
	if header.is_empty(): # Empty string means finished timing
		var head = head_array.pop_back()
		var time_val = time_array.pop_back()
		info("Timed Block [b]%s[/b] finished: [b]%s[/b]" % [head, util.profiler_end(time_val)])
	else: # Non-empty string means starting a new timer
		head_array.push_back(header)
		time_array.push_back(util.profiler_start())

## Takes a script and runs through the virtual method. You
## can pass in variadic parameters through the second argument,
## as an array.
## If script is a string, it is loaded and ran.
## If script is a class name, it is instanced and ran.
## If script is a direct reference to the script of type GDScript,
## it is instanced and ran.
func execute(script, parameters = null):
	var tree = get_tree()
	if script is String:
		var real_script = load(script) as GDScript
		var game_script = real_script.new() as NoteGameScript
		game_script.tree = tree
		game_script.execute(parameters)
		return
	if script is GDScript:
		var game_script = script.new() as NoteGameScript
		game_script.tree = tree
		game_script.execute(parameters)
		return
	var game_script = script.new() as NoteGameScript
	game_script.tree = tree
	game_script.execute(parameters)

## Returns true if Note is using input, or if input should be
## ignored. Providing a context allows for note to return false
## if called from the object blocking input.
func is_input_busy(for_context = null) -> bool:
	if ui.current_window != null:
		return for_context != ui.current_window
	return false

## Returns an empty dictionary if it failed.
## You should implement _export and _import on all your types related to this, except
## for resource types that you will load from disk.
## See the docs for more info. When using to place data in your save file, this
## does not need to be JSON.stringify'd.
func serialize(object) -> Variant:
	var payload = object
	var value
	
	const ExcludedShortcuts = [
		TYPE_ARRAY,
		TYPE_DICTIONARY,
		TYPE_OBJECT,
		TYPE_STRING,
		TYPE_STRING_NAME,
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_BOOL,
		TYPE_NIL
	]
	
	if object is Variant and !ExcludedShortcuts.has(typeof(object)):
		return {
			"_note_literal" = var_to_str(object)
		}
	
	# Before turning structures into owned and serialized values,
	# turn resources, objects, and nodes into their _exported values if they
	# exist, and store their script/packed scene url
	if payload is Resource:
		var script: Script = payload.get_script()
		var uid = ""
		var new_payload = {}
		new_payload[&"resource_script"] = ResourceUID.path_to_uid(script.resource_path)
		if payload.has_method(&"_export"):
			new_payload[&"resource_content"] = payload._export()
		if !payload.resource_path.is_empty():
			new_payload[&"resource_path"] = ResourceUID.path_to_uid(payload.resource_path)
		payload = new_payload
	elif payload is Node:
		var script: Script = payload.get_script()
		var new_payload = {}
		if script == null:
			note.warn("Note Serialize was given a regular node, and that is not yet supported.")
			return null
		new_payload[&"node_script"] = ResourceUID.path_to_uid(script.resource_path)
		if !payload.scene_file_path.is_empty():
			new_payload[&"node_path"] = ResourceUID.path_to_uid(payload.scene_file_path)
		if payload.has_method(&"_export"):
			new_payload[&"node_content"] = payload._export()
		payload = new_payload
	elif payload is Object:
		var script: Script = payload.get_script()
		var new_payload = {}
		if script == null:
			note.warn("Note Serialize was given a regular non-scripted object, and that is not yet supported.")
			return null
		new_payload[&"object_script"] = ResourceUID.path_to_uid(script.resource_path)
		if payload.has_method(&"_export"):
			new_payload[&"object_content"] = payload._export()
		payload = new_payload
	
	# Then after the payload is settled, make sure dictionaries and arrays get
	# sanitized and processed.
	if payload is Array:
		value = []
		for i in payload:
			value.append(serialize(i))
	elif payload is Dictionary:
		value = {}
		for k in payload.keys():
			var ser_k = serialize(k)
			value[ser_k] = serialize(payload[k])
	else:
		value = payload
		
	# Then return the value.
	return value
	
## Reconstructs the resource/node/object that was passed to serialize.
## Returns null if it failed.
## You should implement _export and _import on all your types related to this.
## See the docs for more info.
func deserialize(data) -> Variant:
	var object = null
	if data is Dictionary:
		if data.has("_note_literal"):
			return str_to_var(data["_note_literal"])
		var is_resource = data.has(&"resource_script")
		var is_node = data.has(&"node_script")
		var is_object = data.has(&"object_script")
		if is_resource:
			var new_resource: Resource
			# Try to rehydrate via the resource path
			if data.has(&"resource_path"):
				var resource_path = data[&"resource_path"]
				if loading_screen.is_cached(resource_path):
					new_resource = loading_screen.fetch(resource_path)
				else:
					new_resource = load(resource_path)
			else: # Or create it manually.
				new_resource = Resource.new()
				var script = load(data[&"resource_script"])
				new_resource.set_script(script)
			if new_resource.has_method(&"_import") and data.has(&"resource_content"):
				new_resource._import(deserialize(data[&"resource_content"]))
			object = new_resource
			
		elif is_node:
			var new_node: Node
			if data.has(&"node_path"):
				var node_path = data[&"node_path"]
				if loading_screen.is_cached(node_path):
					new_node = loading_screen.fetch(node_path).instantiate()
				else:
					new_node = load(node_path).instantiate()
			else:
				new_node = Node.new()
				var script = load(data[&"node_script"])
			if new_node.has_method(&"_import") and data.has(&"node_content"):
				new_node._import(deserialize(data[&"node_content"]))
			object = new_node
		elif is_object:
			pass
		else:
			object = {}
			for k in data.keys():
				var deser_k = deserialize(k)
				object[deser_k] = deserialize(data[k])
	elif data is Array:
		object = []
		for d in data:
			object.append(deserialize(d))
	else:
		object = data
		
	return object

## Makes it so the next time the game boots, save select will appear again.
## This has no impact if Sticky Saves are disabled.
func unstick_save():
	meta.stuck_save = ""
	meta.persist(self)

## Ends the current save, and returns to entry.
func return_to_save_select():
	unstick_save()
	end_session()
	var main_scene_prefab = load(ProjectSettings.get_setting("application/run/main_scene", "uid://k7kf706i87f8"))
	level.change_to(main_scene_prefab)

## Called internally to start saves, let note handle this unless you
## know what you want from this! If you are intending to change saves,
## and arent using the simple save selector, prefer to use [code]return_to_save_select[/code]
## so the user can choose a new save instead of doing it for them.
func begin_session(new_session: NoteSaveSession):
	if save == null:
		save = new_session
		info("Loading save file: %s" % save.save_path)
		save.starting()
		save_loaded.emit()
	else:
		warn("Begin Session called despite already having a session. Was this intentional?")
## Called internally to end saves, let note handle this unless you
## know what you want from this! If you are intending to change saves,
## and arent using the simple save selector, prefer to use [code]return_to_save_select[/code]
## so the user can choose a new save instead of doing it for them.
func end_session():
	if save != null:
		info("Unloading save file: "+save.save_path)
		save.ending()
		save = null
		save_unloaded.emit()

extends Node

## Called [b]after[/b] a save is loaded.
signal save_loaded
## Called [b]after[/b] a save is unloaded.
signal save_unloaded

const TypeLoadingScreen = preload("uid://dj5ae4svel0vv")
const TypeControlGuide = preload("uid://b5urykf5xl2tp")
const TypePhaseManager = preload("uid://caty0hb5uijx2")
const TypeTooltipManager = preload("uid://ej2vfmjw2dkq")
const TypeUtil = preload("uid://bqvtnaowd8lta")
const TypeTransitionManager = preload("uid://b53sh8bwtjj8g")
const TypeLevelManager = preload("uid://d1ghq77fsfx07")
const TypeControlManager = preload("uid://dsuqhn7s348wn")
const TypeMetadata = preload("uid://dpj8fxiopchxi")
const TypeFocusGroup = preload("uid://4iwdim3cbvkf")

@export_group("Internal References")
@export var level: TypeLevelManager
@export var controls: TypeControlManager
@export var loading_screen: TypeLoadingScreen
@export var transition: TypeTransitionManager
@export var control_guide: TypeControlGuide
@export var tooltip: TypeTooltipManager
@export var phase: TypePhaseManager
@export var focus: TypeFocusGroup
@export var util: TypeUtil

## This is the Note Dev Settings that you provide via your project settings.
## Do not edit this during runtime with the intention of it being saved!
var settings: NoteDeveloperSettings
## This is the currently loaded save, it can be null before a load.
var save: NoteSaveSession = null

var storage: Dictionary = {}
var meta: TypeMetadata

func _init() -> void:
	var settings_path = ProjectSettings.get_setting("addons/note/settings", "")
	if settings_path == "":
		error("Settings path was not set in project settings: Addons/Note/Settings")
		return
	settings = load(settings_path)
	
func _ready() -> void:
	meta = TypeMetadata.new()
	if settings.save_soft_settings:
		meta.restore_soft_settings(self)
func _notification(what: int) -> void:
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

## Makes it so the next time the game boots, save select will appear again.
## This has no impact if Sticky Saves are disabled.
func unstick_save():
	meta.stuck_save = ""
	meta.persist(self)

## Ends the current save, and returns to entry.
func return_to_save_select():
	unstick_save()
	end_session()
	var main_scene_prefab = load(ProjectSettings.get_setting("application/run/main_scene", "res://addons/note/ENTRY_SCENE.tscn"))
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

extends Control

@export var spinner: Control
@export var progress: ProgressBar

signal loading_file_finished(path: String)
signal loading_file_failed(path: String)
signal loading_shadow_file_finished(path: String)
signal loading_shadow_file_failed(path: String)
signal all_loads_finished

## If you're loading faster than this you should just use a raw load
## for those scenes, as extremely fast load screens can appear as a confusing
## flicker of changing content. This is to make sure load screen
## lasts at least transition time to avoid much confusion and flashing for the user.
## Adjust to your liking, or set to 0.0 to disable.
var minimum_load_time: float = 0.9
var time_loading: float = 0.0
var is_loading: bool = false
var initial_load_quantity: int = 0

## Path : Status
var statuses: PackedStringArray = []
## Path : Status
var statuses_shadows: PackedStringArray = []
## Path : Loaded Resource
var results: Dictionary[String,Variant] = {}
## Path : Error
var errors: Dictionary[String,String] = {}

@onready var _nt = get_tree().root.get_node("note")

## Pushes a path on the stack of things that should be loaded.
func push_item(path: String):
	if is_loading:
		_nt.warn("Pushing new things to load while already loading can result in visual loading screen bugs.")
	if results.has(path):
		_nt.warn("Attempted to queue a loading screen for an already loaded item. Check cache first.")
	ResourceLoader.load_threaded_request(path)
	statuses.append(path)

## Causes a note transition, and shows the loading screen while work happens.
## Listen to signals to know when the loading screen is done.
func begin_loading():
	is_loading = true
	initial_load_quantity = len(statuses)
	_nt.transition.trigger()
	show()
## Pre-loads things in the background immediately without causing any signals or responses.
func shadow_load(path:String):
	ResourceLoader.load_threaded_request(path)
	statuses_shadows.append(path)
## If there are too many loaded files for your liking you can clear the loaded cache.
func clear_cache():
	results.clear()
## Returns true if the file was already loaded.
func is_cached(path: String) -> bool:
	return results.has(path)
func fetch(path: String) -> Variant:
	if results.has(path):
		return results[path]
	else:
		return null
func force_fetch(path: String) -> Variant:
	if results.has(path):
		return results[path]
	else:
		_nt.warn("A cache fetch was forced. Stutters may result from forcing a fetch.")
		var result = ResourceLoader.load_threaded_get(path)
		results[path] = result
		if statuses.has(path):
			statuses.erase(path)
			loading_file_finished.emit(path)
		if statuses_shadows.has(path):
			statuses_shadows.erase(path)
			loading_shadow_file_finished.emit(path)
		return result

func _enter_tree() -> void:
	hide()

func _process_path(path: String) -> float:
	var loading_array = []
	var reply: ResourceLoader.ThreadLoadStatus
	reply = ResourceLoader.load_threaded_get_status(path, loading_array)
	match reply:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			errors[path] = "Failed to load"
			return -1.0
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			errors[path] = "Invalid Resource"
			return -1.0
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			return loading_array[0]
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			_nt.info("Finished loading file %s" % path)
			results[path] = ResourceLoader.load_threaded_get(path)
			return 1.0005 # I fear floating point more than I should, sorry.
	return -1.0
func _process(delta: float) -> void:
	if is_loading:
		time_loading += delta
	spinner.pivot_offset = spinner.size*0.5
	spinner.rotation_degrees += 60.0 * delta
	
	var current_work_done: float = 0.0
	var loading_array = []
	for k in statuses:
		var work = _process_path(k)
		if work >= 1.0:
			statuses.erase(k)
			loading_file_finished.emit(k)
		elif work < 0.0:
			statuses.erase(k)
			loading_file_failed.emit(k)
		else:
			current_work_done += work
	
	progress.min_value = 0.0
	progress.max_value = float(initial_load_quantity)
	progress.value = current_work_done
	for k in statuses_shadows:
		var work = _process_path(k)
		if work >= 1.0:
			statuses_shadows.erase(k)
			loading_shadow_file_finished.emit(k)
		elif work < 0.0:
			statuses_shadows.erase(k)
			loading_shadow_file_failed.emit(k)
	
	if statuses.is_empty() and time_loading >= minimum_load_time:
		is_loading = false
		all_loads_finished.emit()

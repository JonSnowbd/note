extends Node

class LoadingSession extends RefCounted:
	var tree: SceneTree
	var time_spent: float = 0.0
	var items_to_load: Array[String] = []
	var items_to_warm: Array[String] = []
	var await_signals: Array[Signal] = []
	var skip_loading: bool = false
	var running: bool = false
	var destination = null
	
	var done_loading: bool = false
	var done_waiting: bool = false
	## Adds a single signal to track. The loading screen will not be considered
	## as done until all signals have been triggered. You can use this to make
	## a load wait for your level generation for example. Waiting for signals happens
	## only after the level has been loaded
	func load_wait_signal(blocking_signal: Signal) -> LoadingSession:
		await_signals.append(blocking_signal)
		return self
	## Adds signals to track. The loading screen will not be considered
	## as done until all signals have been triggered. You can use this to make
	## a load wait for your level generation for example.
	func load_wait_signals(blocking_signals: Array[Signal]) -> LoadingSession:
		await_signals.append_array(blocking_signals)
		return self
	## Adds a single asset to be prewarmed as this load happens.
	## The load screen will not wait for this asset to be done before
	## transitioning.
	func load_prewarm_asset(asset: String) -> LoadingSession:
		items_to_warm.append(asset)
		return self
	## Adds assets to be prewarmed as this load happens.
	## The load screen will not wait for this asset to be done before
	## transitioning.
	func load_prewarm_assets(assets: Array[String]) -> LoadingSession:
		items_to_warm.append_array(assets)
		return self
	## Adds a single asset to be loaded.
	func load_asset(asset: String) -> LoadingSession:
		items_to_load.append(asset)
		return self
	## Adds assets to be loaded.
	func load_assets(assets: Array[String]) -> LoadingSession:
		items_to_load.append_array(assets)
		return self
	
	## Begins the loading process. Unloads and frees the current level, and goes to the next
	## level.[br][br] Level_scene can be a string for a path, a packed scene for the level,
	## or an App VMU callback to use a special application mode full screen gui.
	func level(level_scene) -> void:
		var old = level_swap(level_scene)
		if old != null and is_instance_valid(old):
			old.queue_free()
	## Begins the loading process. Eeturns the current level, and goes to the next
	## level.[br][br] Level_scene can be a string for a path, a packed scene for the level,
	## or an App VMU callback to use a special application mode full screen gui.
	func level_swap(level_scene) -> Node:
		var old_scene = tree.current_scene
		running = true
		
		destination = level_scene
		if old_scene != null:
			tree.current_scene = null
			tree.root.remove_child.call_deferred(old_scene)
		
		if skip_loading:
			time_spent = 999.0
			if level_scene is String:
				destination = note.loading.fetch(level_scene)
			if level_scene is PackedScene:
				destination = level_scene
			for i in items_to_load:
				var _discard = note.loading.fetch(i)
			for i in items_to_warm:
				note.loading.prewarm(i)
			items_to_load.clear()
			items_to_warm.clear()
			running = false
			_finish()
			return old_scene
		
		if (
			(destination is PackedScene) 
			or 
			(destination is String and note.loading.is_cached(destination))
		):
			if items_to_load.is_empty() and await_signals.is_empty():
				running = false
				time_spent = 999.0
				_finish()
		
		if destination is String:
			note.loading.prewarm(destination)
			items_to_load.append(destination)
		for i in items_to_warm:
			note.loading.prewarm(i)
		items_to_warm.clear()
		return old_scene
	
	func _is_finished(delta: float) -> bool:
		if time_spent < note.settings.loading_screen_minimum_time:
			return false
		for i in items_to_load:
			if !note.loading.is_cached(i): return false
		if !await_signals.is_empty():
			return false
		return true
	
	func _finish():
		note.loading.loading_screen_visual_root.hide()
		var scene: Node
		if destination is String:
			scene = note.loading.fetch(destination).instantiate()
		elif destination is PackedScene:
			scene = destination.instantiate()
		elif destination is Node:
			scene = destination
			if scene.get_parent() != null:
				scene.get_parent().remove_child(scene)
		
		tree.change_scene_to_node.call_deferred(scene)

## The loading screens root, which contains the visuals, and the autosave piece.
@export var loading_screen_root: Control
## The loading screens visuals.
@export var loading_screen_visual_root: Control
@export var centerpiece_container: Container
@export var loading_screen_blackout: ColorRect
@export var loading_screen_tip: Label

signal prewarm_finished(path: String)
signal prewarm_failed(path: String)
signal loading_update(completion: float)

var current_load_session: LoadingSession

## Path : Status
var statuses: PackedStringArray = []
## Path : Status
var statuses_shadows: PackedStringArray = []
## Path : Loaded Resource
var results: Dictionary[String,Variant] = {}

## Causes a note transition, and shows the loading screen while work happens.
## Listen to signals to know when the loading screen is done. If you've already warmed
## the relevant assets, the loading screen will be skipped.
## [br][br] IMPORTANT! The current scene is unloaded after you finish
## configuring the load.
func begin_loading_screen() -> LoadingSession:
	note.transition.trigger()
	loading_screen_visual_root.show()
	var session = LoadingSession.new()
	session.tree = get_tree()
	current_load_session = session
	return session

func quick_level(level_scene) -> void:
	begin_loading_screen().level(level_scene)
func quick_level_swap(level_scene) -> Node:
	return begin_loading_screen().level_swap(level_scene)
func is_loading() -> bool:
	return current_load_session != null
## If there are too many loaded files for your liking you can clear the loaded cache.
func clear_cache():
	results.clear()
## Returns true if the file was already loaded or pre-warmed.
func is_cached(path: String) -> bool:
	return results.has(path)
## Pre-loads things in the background immediately without causing any signals or responses.
func prewarm(path:String):
	if results.has(path) or statuses.has(path) or statuses_shadows.has(path):
		return
	ResourceLoader.load_threaded_request(path)
	statuses_shadows.append(path)
## If the path given is loaded, it will be forgotten by note loading.
## Note: the memory will still be occupied if you have stored a reference to it
## elsewhere in your code.
func unload(path:String):
	results.erase(path)
## If the path has been fetched or prewarmed, this is an extremely quick operation, otherwise
## a loading hitch may occur. Consider prewarming assets via code or the preloader node.
func fetch(path: String) -> Variant:
	if results.has(path):
		return results[path]
	else:
		var result
		if !statuses.has(path) and !statuses_shadows.has(path):
			result = load(path)
		else:
			result = ResourceLoader.load_threaded_get(path)
		results[path] = result
		if statuses.has(path):
			statuses.erase(path)
		if statuses_shadows.has(path):
			statuses_shadows.erase(path)
			prewarm_finished.emit(path)
		return result

func _process_path(path: String) -> float:
	var loading_array = []
	var reply: ResourceLoader.ThreadLoadStatus
	reply = ResourceLoader.load_threaded_get_status(path, loading_array)
	match reply:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			note.error("Failed to load: %s" % path)
			return -1.0
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			note.error("Invalid resource: %s" % path)
			return -1.0
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			return loading_array[0]
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			if note.settings.note_info_prints:
				note.info("Finished loading file %s" % path)
			results[path] = ResourceLoader.load_threaded_get(path)
			return 1.0005 # I fear floating point more than I should, sorry.
	return -1.0


func _ready() -> void:
	if note.settings.loading_screen_centerpiece != null:
		var new_piece = note.settings.loading_screen_centerpiece.instantiate()
		centerpiece_container.add_child(new_piece)
	loading_screen_blackout.color = note.settings.loading_screen_blackout_color
func _process(delta: float) -> void:
	var current_work_done: float = 0.0
	var loading_array = []
	for k in statuses:
		var work = _process_path(k)
		if work >= 1.0:
			statuses.erase(k)
		elif work < 0.0:
			statuses.erase(k)
		else:
			current_work_done += work
	for k in statuses_shadows:
		var work = _process_path(k)
		if work >= 1.0:
			statuses_shadows.erase(k)
			prewarm_finished.emit(k)
		elif work < 0.0:
			statuses_shadows.erase(k)
			prewarm_failed.emit(k)
	if current_load_session != null:
		current_load_session.time_spent += delta
		if current_load_session.running:
			if current_load_session._is_finished(delta):
				note.transition.trigger()
				current_load_session._finish()
				current_load_session = null

extends Node

@export_category("References")
@export var container: CanvasLayer
@export var screen_cover: TextureRect
@export var blackout: ColorRect

signal control_mode_changed

var is_gamepad: bool = false
var _mouse_track: float = 0.0

var control_guide: ControlGuideManager
var tooltip: TooltipManager
var popup: PopupManager
var phaser: NotePhaseManager

signal loading_change(progress: float)

var services: Dictionary = {}
var storage: Dictionary = {}

var util: NoteUtilities
var loading_screen: Node

var _transition_cap: float = 0.0
var _transition_time: float = 0.0

var _transition_progress_name: String = ""
var _pulse_interval: float = 0.0
var _pulse_timer: float = 0.0

var current_session: NoteSaveSession = null

func _init() -> void:
	util = NoteUtilities.new()
	add_child(util)
func set_gamepad_mode(should_be_gamepad: bool):
	if !ProjectSettings.get_setting("addons/note/controller_detection", true):
		return
	if should_be_gamepad:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_gamepad != should_be_gamepad:
		is_gamepad = should_be_gamepad
		control_mode_changed.emit()
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_track += event.relative.length()
		if _mouse_track > 100.0:
			_mouse_track = 0.0
			set_gamepad_mode(false)
	if event is InputEventKey or event is InputEventMouseButton:
		set_gamepad_mode(false)
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		set_gamepad_mode(true)
func _ready() -> void:
	_pulse_interval = ProjectSettings.get_setting("addons/note/save_pulse_period", 1.0)
	control_guide = load(ProjectSettings.get_setting("addons/note/user/control_guide_prefab", NoteEditorPlugin.default_control_guide)).instantiate()
	container.add_child(control_guide)
	tooltip = load(ProjectSettings.get_setting("addons/note/user/tooltip_prefab", NoteEditorPlugin.default_tooltip)).instantiate()
	container.add_child(tooltip)
	popup = load(ProjectSettings.get_setting("addons/note/user/popup_manager_prefab", NoteEditorPlugin.default_popup_system)).instantiate()
	container.add_child(popup)
	phaser = load(ProjectSettings.get_setting("addons/note/user/phaser_manager_prefab", NoteEditorPlugin.default_phaser_manager)).instantiate()
	add_child(phaser)
	
	var screen_material = load(ProjectSettings.get_setting("addons/note/transition/material", NoteEditorPlugin.default_transition))
	screen_cover.material = screen_material as ShaderMaterial
	_transition_progress_name = ProjectSettings.get_setting("addons/note/transition/parameter", NoteEditorPlugin.default_transition_parameter)
	
	var loading_prefab: PackedScene = load(ProjectSettings.get_setting("addons/note/transition/loading_screen", NoteEditorPlugin.default_loading_screen))
	var screen = loading_prefab.instantiate()
	add_child(screen)
	loading_screen = screen
	loading_screen.hide()
	loading_screen.process_mode = Node.PROCESS_MODE_DISABLED

func _message(header: String, separator: String = " >> ", message: String = ""):
	var time: float = float(Time.get_ticks_msec()) / 1000.0
	print_rich("[color=grey]"+util.seconds_to_speedrun_stamp(time)+"[/color] "+header+separator+message)
func info(message: String, header: String = "Note"):
	_message(header, " >> ", message)
func warn(message: String, header: String = "Note"):
	_message("[color=yellow]"+header, " !! ", message)
func error(message: String, data=null, header: String = "Error"):
	_message("[color=red]"+header, " !! ", message)
	var error_packed: PackedScene = load(ProjectSettings.get_setting("addons/note/user/error_screen", NoteEditorPlugin.default_error_screen))
	var err_scene: NoteErrorScene = error_packed.instantiate() as NoteErrorScene
	err_scene.set_error(header, message, "\n".join(get_stack().map(str)))
	transition(0.5)
	await get_tree().process_frame
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().root.add_child(err_scene)
	get_tree().current_scene = err_scene

## Changes the transition material and progression uniform name used in note transitions.
func set_transition(t: ShaderMaterial, t_prog_name: String = "progress"):
	screen_cover.material = t
	_transition_progress_name = t_prog_name

## Subscribes to the event which can be anything you want.
## I recommend using the event class itself.
## Subscriber must have an `_event(notification, data)` function.
func listen(event, subscriber: Object):
	if !subscriber.has_method("_event"):
		note.error(str(subscriber)+" has no _event function, but attempted to listen to event.")
		return
	var hashed: String = util.cached_hash_str(event)
	if !has_user_signal(hashed):
		add_user_signal(hashed, [
			{"name" = "event_type", "type" = TYPE_OBJECT},
			{"name" = "event_payload", "type" = TYPE_OBJECT},
		])
	connect(hashed, subscriber._event)
## Stops listening to an event. You should do this when freeing a node.
func unlisten(event, subscriber: Object):
	var hashed: String = util.cached_hash_str(event)
	if has_user_signal(hashed):
		disconnect(hashed, subscriber._event)

## Sends an event to every subscriber under the value of event
func send(event, data = null):
	var hashed: String = util.cached_hash_str(event)
	if has_user_signal(hashed):
		emit_signal(hashed, event, data)

## Designates an object as a service provider.
## identifier is what it will be stored under, and what
## seekers must use to find the object.
func designate_service(identifier, object: Object):
	if !services.has(identifier):
		services[identifier] = []
	var service_array: Array = services[identifier]
	service_array.push_back(object)
## Marks a server as destroyed.
func destroy_service(identifier, object: Object):
	if services.has(identifier):
		var service_array: Array = services[identifier]
		service_array.erase(object)
		if len(service_array) == 0:
			services.erase(identifier)
## Finds the latest object to identify as this service.
## Can return null so keep that in mind.
func locate_service(identifier) -> Object:
	if services.has(identifier):
		if len(services[identifier]) > 0:
			return services[identifier][0]
	return null


## Makes it so the next time the game boots, save select will appear again.
func unstick_save():
	if FileAccess.file_exists("user://_note.json"):
		var file = FileAccess.open("user://_note.json", FileAccess.READ_WRITE)
		var dict = JSON.parse_string(file.get_as_text())
		dict["save_stuck"] = false
		file.store_string(JSON.stringify(dict))
		file.close()
## Ends the current save, and returns to entry.
func return_to_save_select():
	unstick_save()
	unload_save()
	load_level(load(ProjectSettings.get_setting("application/run/main_scene", "res://addons/note/ENTRY_SCENE.tscn")))

func _process(delta: float) -> void:
	_pulse_timer += delta
	while _pulse_timer >= _pulse_interval:
		if current_session != null:
			current_session.pulse(_pulse_interval)
		_pulse_timer -= _pulse_interval
	if _transition_time >= 0.0:
		_transition_time -= util.unscaled_dt()
		if _transition_time < 0.0:
			screen_cover.call_deferred("hide")
		var mat: ShaderMaterial = screen_cover.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter(_transition_progress_name, 1.0-clamp(_transition_time/_transition_cap, 0.0, 1.0))

## Not recommended to call this yourself unless you know what you want from it.
func unload_save():
	if current_session != null:
		info("Unloading save file: "+current_session.save_path)
		current_session.ending()
		current_session = null
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		unload_save()

## Takes a snapshot of the viewport, sets the texture into the screen cover,
## then transitions the material's parameter from 0.0 to 1.0 and hides the cover.
## If you're transitioning a level manually, just call this, then change the level.
func transition(time: float = 0.33):
	_transition_cap = time
	_transition_time = time
	var img = get_viewport().get_texture().get_image()
	screen_cover.texture = ImageTexture.create_from_image(img)
	screen_cover.show()
	if screen_cover.material is ShaderMaterial:
		screen_cover.material.set_shader_parameter(_transition_progress_name, 0.0)
		screen_cover.material.set_shader_parameter("seed", randf()*30000.0)

func unload_level():
	info("Unloading current level")
	var cs = get_tree().current_scene
	cs.queue_free()
	get_tree().root.remove_child(cs)
	get_tree().current_scene = null
## Like load level, but instead of freeing the current scene, returns it.
func swap_level(packed_scene: PackedScene, transition_time: float = 0.75) -> Node:
	transition(transition_time)
	info("Swapping to new preloaded level: "+packed_scene.resource_path)
	var cs = get_tree().current_scene
	cs.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().root.remove_child(cs)
	get_tree().current_scene = null
	get_tree().change_scene_to_packed(packed_scene)
	return cs
func swap_level_with_loading_screen(path: String, transition_time: float = 0.75) -> Node:
	if ResourceLoader.has_cached(path):
		return swap_level(load(path), transition_time)
	info("Swapping to new level: "+path)
	transition(transition_time)
	loading_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	loading_change.emit(0.0)
	loading_screen.show()
	var cs = get_tree().current_scene
	cs.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().root.remove_child(cs)
	get_tree().current_scene = null
	var loader = ResourceLoader.load_threaded_request(path, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE)
	var progress = []
	var reply = ResourceLoader.load_threaded_get_status(path, progress)
	while reply == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if len(progress) > 0:
			loading_change.emit(progress[0])
		progress.clear()
		reply = ResourceLoader.load_threaded_get_status(path, progress)
		await get_tree().process_frame
	if reply == ResourceLoader.THREAD_LOAD_LOADED:
		var loaded_level: PackedScene = ResourceLoader.load_threaded_get(path)
		loaded_level.take_over_path(path)
		transition(transition_time)
		loading_screen.call_deferred("hide")
		loading_screen.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		get_tree().change_scene_to_packed(loaded_level)
	else:
		error("Failed to load resource "+path)
	return cs
func load_level(packed_scene: PackedScene, transition_time: float = 0.75):
	transition(transition_time)
	get_tree().change_scene_to_packed(packed_scene)
func load_level_with_loading_screen(path: String, transition_time: float = 0.75):
	if ResourceLoader.has_cached(path):
		load_level(load(path), transition_time)
		return
	var original_scene = await swap_level_with_loading_screen(path, transition_time)
	original_scene.queue_free()

extends Node

signal async_load_finished

var _load_awaiting: String = ""
func _load_done_callback(path: String):
	if _load_awaiting == path:
		if note.loading_screen.minimum_load_time <= 0.0:
			async_load_finished.emit()
			_load_awaiting = ""
		else:
			var time_left = note.loading_screen.minimum_load_time - note.loading_screen.time_loading
			if time_left > 0.1:
				var timer = get_tree().create_timer(time_left)
				timer.timeout.connect(func():
					async_load_finished.emit()
					_load_awaiting = ""
				)
			else:
				async_load_finished.emit()
				_load_awaiting = ""

var transition_time: float = 0.6
var log_info: bool = false

func _internal_swap_logic(new_scene, with_loading_screen: bool, with_transition: bool = true) -> Array[Node]:
	if !_load_awaiting.is_empty():
		note.error("Scene change was requested during a loading screen, skipping request.")
		return []
	
	var old_scene: Node = get_tree().current_scene
	var new_scene_instance: Node

	if new_scene is String:
		if with_loading_screen:
			_load_awaiting = new_scene
			note.loading_screen.push_item(new_scene)
			note.loading_screen.begin_loading()
			await async_load_finished
			var packed: PackedScene = note.loading_screen.force_fetch(new_scene)
			if packed == null:
				note.error("Note failed to load path %s."%new_scene)
				return []
			new_scene_instance = packed.instantiate()
		else:
			var prefab = load(new_scene) as PackedScene
			if prefab == null: 
				note.error("Provided string to load was not a packed scene.")
				return []
			new_scene_instance = prefab.instantiate()
	elif new_scene is PackedScene:
		if with_loading_screen:
			note.warn("'With load screen' was specified in change level, but was given an already loaded asset.")
		new_scene_instance = new_scene.instantiate()
	elif new_scene is Node:
		if with_loading_screen:
			note.warn("'With load screen' was specified in change level, but was given an already instanced asset.")
		if new_scene.get_parent() != null:
			note.warn("Instanced scene given to level load already belonged to a parent, removing it from the parent.")
			new_scene.get_parent().remove_child(new_scene)
		new_scene_instance = new_scene
		
	
	if with_transition:
		note.transition.trigger(transition_time)
	note.loading_screen.hide()
	get_tree().root.call_deferred("remove_child",old_scene)
	get_tree().root.call_deferred("add_child",new_scene_instance)
	get_tree().set_deferred("current_scene", new_scene_instance)
	return [old_scene, new_scene_instance]

## Changes to the new scene with an optional load screen. The old
## scene is unloaded and deleted.[br]
## - If new scene is a string, it is loaded and instantiated.[br]
## - If new scene is a packed scene, it is instantiated and loaded.[br]
## - If new scene is a node, it is placed into the tree and resumed.[br]
## Returns the new scene.
func change_to(new_scene, with_loading_screen: bool = false, with_transition: bool = true) -> Node:
	var scene_data = await _internal_swap_logic(new_scene, with_loading_screen, with_transition)
	var old_scene = scene_data[0]
	if old_scene != null:
		old_scene.queue_free()
	if note.settings.note_info_prints:
		note.info("Finished transition to new level %s" % get_tree().current_scene.name)
	return scene_data[1]

## Changes to the new scene with an optional load screen.[br]
## - If new scene is a string, it is loaded and instantiated.[br]
## - If new scene is a packed scene, it is instantiated and loaded.[br]
## - If new scene is a node, it is placed into the tree and resumed.[br]
func swap(new_scene, with_loading_screen: bool = false, with_transition: bool = true) -> Node:
	var scene_data = await _internal_swap_logic(new_scene, with_loading_screen, with_transition)
	var old_scene = scene_data[0]
	if note.settings.note_info_prints:
		note.info("Finished transition to new level %s" % scene_data[1].name)
	return old_scene

func _ready() -> void:
	note.loading_screen.loading_file_finished.connect(_load_done_callback)

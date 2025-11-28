extends CanvasLayer
const PillType = preload("uid://pufbtr67lcto")

@export var pills: Array[PillType] = []
@export var splash_screen_duration: float = 3.0

@export var splash_screen: Control
@export var splash_cover: Control
@export var credit_container: Control
@export var godot_credit_logo: Control
@export var note_credit_logo: Control
@export var your_credit_logo: Control

@onready var _nt = get_tree().root.get_node("note")

var countdown: float = 0.0
var save_loaded: bool = false

func save_exists(profile_name: String) -> bool:
	return DirAccess.dir_exists_absolute("user://profile_"+profile_name)

func get_save_faceplate(profile_name: String) -> Control:
	var base_folder = "user://profile_"+profile_name
	var save_type = NoteSaveSession
	if _nt.settings.save_session_type != null:
		save_type = _nt.settings.save_session_type
	
	var new_save: NoteSaveSession = save_type.new(base_folder, false)
	var result = new_save.get_fancy_pill()
	new_save.queue_free()
	return result

func create_save(profile_name: String):
	var base_folder = "user://profile_"+profile_name
	DirAccess.make_dir_recursive_absolute(base_folder)
	var meta_data = {
		"creation_date" = Time.get_unix_time_from_system(),
	}
	var mfi = FileAccess.open(base_folder+"/__note_meta.json", FileAccess.WRITE)
	mfi.store_string(JSON.stringify(meta_data))
	mfi.close()
	
	var fti = FileAccess.open(base_folder+"/first_timer_indicator", FileAccess.WRITE)
	fti.close()
	
func load_save(profile_name: String):
	var base_folder = "user://profile_"+profile_name
	var meta_file = FileAccess.open(base_folder+"/__note_meta.json", FileAccess.READ)
	
	var save_type = NoteSaveSession
	if _nt.settings.save_session_type != null:
		save_type = _nt.settings.save_session_type
	
	var new_save: NoteSaveSession = save_type.new(base_folder)
	_nt.begin_session(new_save)
	save_loaded = true

## Finishes the load, moves onto the user's defined entry point.
func post_load_action(skip_animation: bool = false):
	if _nt.loading_screen.is_cached(_nt.settings.initial_scene):
		_nt.level.change_to(_nt.settings.initial_scene)
		return
	if skip_animation:
		_nt.loading_screen.show()
		await get_tree().process_frame
		_nt.level.change_to(_nt.settings.initial_scene, true)
	else:
		_nt.level.change_to(_nt.settings.initial_scene, true)

func end_splash_screen():
	_nt.transition.trigger()
	splash_screen.hide()
func soft_settings_check():
	## Restore soft settings if they are available.
	if _nt.settings.save_soft_settings:
		if !_nt.meta.first_launch:
			_nt.info("Soft save settings restored.")
			_nt.meta.restore_soft_settings(_nt)
		else:
			_nt.info("Soft save settings detected first launch. Not restoring settings.")
func instant_load_check():
	var is_simple = _nt.settings.save_strategy == NoteDeveloperSettings.NoteEntrySceneType.SIMPLE
	var uses_stuck_save = _nt.settings.save_sticky
	if is_simple:
		if save_exists("simple_profile"):
			_nt.info("Loading pre-existing simple profile")
			load_save("simple_profile")
		else:
			_nt.info("Creating and loading first simple profile")
			create_save("simple_profile")
			load_save("simple_profile")
	if !_nt.meta.stuck_save.is_empty() and !is_simple and uses_stuck_save:
		var stuck_save_exists = save_exists(_nt.meta.stuck_save)
		if stuck_save_exists:
			_nt.info("Automatically loading 'stuck save' profile <%s>"%_nt.meta.stuck_save)
			load_save(_nt.meta.stuck_save)

func begin_save_screen():
	if save_loaded:
		call_deferred("post_load_action")
		return

	show()
	for i in range(len(pills)):
		var profile_name = "save%d"%i
		var exists = save_exists(profile_name)
		if exists:
			var face_plate = get_save_faceplate(profile_name)
			pills[i].set_state_save_exists(profile_name)
			if face_plate != null:
				pills[i].set_face_plate(face_plate)
		else:
			pills[i].set_state_waiting_for(profile_name)
		pills[i].selected.connect(func():
			if exists:
				_nt.info("Loading profile <%s>" % profile_name)
				load_save(profile_name)
			else:
				_nt.info("Creating and then loading profile <%s>" % profile_name)
				create_save(profile_name)
				load_save(profile_name)
			if _nt.settings.save_sticky:
				_nt.info("'Sticking' save profile <%s>" % profile_name)
				_nt.meta.stuck_save = profile_name
				_nt.meta.persist(_nt)
			call_deferred("post_load_action")
		)
	

func _ready() -> void:
	_nt.loading_screen.shadow_load(_nt.settings.initial_scene)
	instant_load_check()
	countdown = splash_screen_duration
	var t = create_tween()
	t.tween_property(splash_cover, "modulate:a", 0.0, 0.5)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_CUBIC)

func _process(delta: float) -> void:
	var gp_hit = Input.is_joy_button_pressed(0, JOY_BUTTON_START) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var kb_hit = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ESCAPE)

	if gp_hit or kb_hit:
		if countdown > 0.25:
			countdown = 0.2
	if countdown >= 0.0:
		countdown -= delta
		if countdown <= 0.0:
			end_splash_screen()
			begin_save_screen()

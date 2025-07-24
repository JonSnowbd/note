@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("note", "res://addons/note/prefab/note_center.tscn")
	if !ProjectSettings.has_setting("addons/note/transition/material"):
		ProjectSettings.set_setting("addons/note/transition/material", note.default_transition)
	ProjectSettings.set_initial_value("addons/note/transition/material", note.default_transition)
	ProjectSettings.set_as_basic("addons/note/transition/material", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/transition/material",
		"type": TYPE_STRING,
		"editor_description": "The [c]ShaderMaterial[/c] used to hide scene transitions. It should have\
  a shader parameter that can be scaled from 0 to 1 that fades to transparency.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.res,*.tres" 
	})
	if !ProjectSettings.has_setting("addons/note/transition/parameter"):
		ProjectSettings.set_setting("addons/note/transition/parameter", note.default_transition_parameter)
	ProjectSettings.set_initial_value("addons/note/transition/parameter", note.default_transition_parameter)
	ProjectSettings.set_as_basic("addons/note/transition/parameter", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/transition/parameter",
		"type": TYPE_STRING,
	})
	if !ProjectSettings.has_setting("addons/note/controller_detection"):
		ProjectSettings.set_setting("addons/note/controller_detection", true)
	ProjectSettings.set_initial_value("addons/note/controller_detection", true)
	ProjectSettings.set_as_basic("addons/note/controller_detection", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/controller_detection",
		"type": TYPE_BOOL,
	})
	if !ProjectSettings.has_setting("addons/note/transition/loading_screen"):
		ProjectSettings.set_setting("addons/note/transition/loading_screen", note.default_loading_screen)
	ProjectSettings.set_initial_value("addons/note/transition/loading_screen", note.default_loading_screen)
	ProjectSettings.set_as_basic("addons/note/transition/loading_screen", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/transition/loading_screen",
		"type": TYPE_STRING,
		"tooltip": "The prefab for loading screens.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.scn,*.tscn" 
	})
	if !ProjectSettings.has_setting("addons/note/user/error_screen"):
		ProjectSettings.set_setting("addons/note/user/error_screen", note.default_error_screen)
	ProjectSettings.set_initial_value("addons/note/user/error_screen", note.default_error_screen)
	ProjectSettings.set_as_basic("addons/note/user/error_screen", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/user/error_screen",
		"type": TYPE_STRING,
		"tooltip": "The prefab for errors.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.scn,*.tscn" 
	})
	if !ProjectSettings.has_setting("addons/note/user/control_guide_prefab"):
		ProjectSettings.set_setting("addons/note/user/control_guide_prefab", note.default_control_guide)
	ProjectSettings.set_initial_value("addons/note/user/control_guide_prefab", note.default_control_guide)
	ProjectSettings.set_as_basic("addons/note/user/control_guide_prefab", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/user/control_guide_prefab",
		"type": TYPE_STRING,
		"tooltip": "The prefab for the control guide system.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.scn,*.tscn" 
	})
	if !ProjectSettings.has_setting("addons/note/user/popup_manager_prefab"):
		ProjectSettings.set_setting("addons/note/user/popup_manager_prefab", note.default_popup_system)
	ProjectSettings.set_initial_value("addons/note/user/popup_manager_prefab", note.default_popup_system)
	ProjectSettings.set_as_basic("addons/note/user/popup_manager_prefab", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/user/popup_manager_prefab",
		"type": TYPE_STRING,
		"tooltip": "The prefab for the popup message guide system.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.scn,*.tscn" 
	})
	if !ProjectSettings.has_setting("addons/note/user/tooltip_prefab"):
		ProjectSettings.set_setting("addons/note/user/tooltip_prefab", note.default_tooltip)
	ProjectSettings.set_initial_value("addons/note/user/tooltip_prefab", note.default_tooltip)
	ProjectSettings.set_as_basic("addons/note/user/tooltip_prefab", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/user/tooltip_prefab",
		"type": TYPE_STRING,
		"tooltip": "The prefab for the tooltip system.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.scn,*.tscn" 
	})
	if !ProjectSettings.has_setting("addons/note/user/phaser_manager_prefab"):
		ProjectSettings.set_setting("addons/note/user/phaser_manager_prefab", note.default_phaser_manager)
	ProjectSettings.set_initial_value("addons/note/user/phaser_manager_prefab", note.default_phaser_manager)
	ProjectSettings.set_as_basic("addons/note/user/phaser_manager_prefab", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/user/phaser_manager_prefab",
		"type": TYPE_STRING,
		"tooltip": "The prefab for the phaser system.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.scn,*.tscn" 
	})
	if !ProjectSettings.has_setting("addons/note/save_session_type"):
		ProjectSettings.set_setting("addons/note/save_session_type", note.default_save_session)
	ProjectSettings.set_initial_value("addons/note/save_session_type", note.default_save_session)
	ProjectSettings.set_as_basic("addons/note/save_session_type", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/save_session_type",
		"type": TYPE_STRING,
		"tooltip": "Your type for a note save session.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.gd,*.tscn,*.scn" 
	})
	if !ProjectSettings.has_setting("addons/note/user/entry_point"):
		push_warning("The Note plugin needs an entry point for your game. Please assign it in Project Settings -> Addons -> Note -> Entry Point")
		ProjectSettings.set_setting("addons/note/user/entry_point", "")
	ProjectSettings.set_initial_value("addons/note/user/entry_point", "")
	ProjectSettings.set_as_basic("addons/note/user/entry_point", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/user/entry_point",
		"type": TYPE_STRING,
		"tooltip": "The prefab for loading the game.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tscn,*.scn" 
	})
	if !ProjectSettings.has_setting("addons/note/dev/prefix"):
		ProjectSettings.set_setting("addons/note/dev/prefix", "__")
	ProjectSettings.set_initial_value("addons/note/dev/prefix", "__")
	ProjectSettings.set_as_basic("addons/note/dev/prefix", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/dev/prefix",
		"description": "If a save file starts with this string, it is marked as a dev save, and will use the dev init.",
		"type": TYPE_STRING,
	})
	if !ProjectSettings.has_setting("addons/note/dev/dev_entry_point"):
		ProjectSettings.set_setting("addons/note/dev/dev_entry_point", "")
	ProjectSettings.set_initial_value("addons/note/dev/dev_entry_point", "")
	ProjectSettings.set_as_basic("addons/note/dev/dev_entry_point", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/dev/dev_entry_point",
		"type": TYPE_STRING,
		"tooltip": "If a save file starts with this string, it is marked as a dev save, and will use the dev init.",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tscn,*.scn" 
	})
	if !ProjectSettings.has_setting("addons/note/sticky_save"):
		ProjectSettings.set_setting("addons/note/sticky_save", true)
	ProjectSettings.set_initial_value("addons/note/sticky_save", true)
	ProjectSettings.set_as_basic("addons/note/sticky_save", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/sticky_save",
		"type": TYPE_BOOL,
		"tooltip": "If true, the user will be stuck on the chosen save on boot until they manually return to save select.",
	})
	if !ProjectSettings.has_setting("addons/note/save_pulse_period"):
		ProjectSettings.set_setting("addons/note/save_pulse_period", 1.0)
	ProjectSettings.set_initial_value("addons/note/save_pulse_period", 1.0)
	ProjectSettings.set_as_basic("addons/note/save_pulse_period", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/save_pulse_period",
		"type": TYPE_FLOAT,
		"tooltip": "The time between each 'pulse' sent to the save session. Defaults to every second.",
	})
	ProjectSettings.save()


func _exit_tree() -> void:
	remove_autoload_singleton("note")

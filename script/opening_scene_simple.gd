extends Node

func _enter_tree() -> void:
	var SessionType = load(ProjectSettings.get_setting("addons/note/save_session_type", note.default_save_session))
	if !DirAccess.dir_exists_absolute("user://simple_profile"):
		DirAccess.make_dir_absolute("user://simple_profile")
	var new_session: NoteSaveSession = SessionType.new("user://simple_profile", false) as NoteSaveSession
	
	if new_session == null:
		push_error("Failed to load session type, is your `Addons/Note/Save Session Type` a descendant of NoteSaveSession?")
	note.current_session = new_session
	var init_path =  ProjectSettings.get_setting("addons/note/user/entry_point", "")
	get_tree().call_deferred("change_scene_to_file",init_path)

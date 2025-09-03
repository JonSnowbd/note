extends Node2D

@export_category("References")
@export var tree: Tree
@export var text_entry_root: Control

@export_category("Actions")
@export var quit_button: Button
@export var create_save_button: Button
@export var create_category_button: Button
@export var delete_button: Button
@export var load_button: Button

@export_category("Text Entry Related")
@export var text_entry_label: Label
@export var confirm_text_entry: Button
@export var cancel_text_entry: Button
@export var text_entry: LineEdit

var saves: Array[String] = []
var action = "none"
var delete_timeout: float = -1.0
var sticky: bool = false

func _explore_folder(parent: TreeItem, folder: String):
	var iter = DirAccess.get_directories_at(folder)
	var folders = []
	for fol: String in iter:
		var full_path: String
		if folder.ends_with("/"):
			full_path = folder+fol
		else:
			full_path = folder+"/"+fol
		if fol.begins_with("save_"):
			var item = tree.create_item(parent)
			item.set_text(0, fol.substr(5).capitalize())
			item.set_metadata(0, {
				path = full_path,
				is_save = true
			})
		if fol.begins_with("category_"):
			var item = tree.create_item(parent)
			item.set_text(0, "📁 "+fol.substr(9).capitalize())
			item.set_metadata(0, {
				path = full_path,
				is_save = false
			})
			_explore_folder(item, full_path)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sticky = ProjectSettings.get_setting("addons/note/sticky_save", true)
	if sticky:
		if FileAccess.file_exists("user://_note.json"):
			var file = FileAccess.open("user://_note.json", FileAccess.READ)
			var dict = JSON.parse_string(file.get_as_text())
			file.close()
			if dict["save_stuck"]:
				load_save(dict["save_path"], true)
				return
	refresh()
	tree.item_selected.connect(selection_changed)
	quit_button.pressed.connect(get_tree().quit)
	load_button.pressed.connect(tree_confirm)
	tree.item_activated.connect(tree_confirm)
	
	create_category_button.pressed.connect(action_create_category)
	create_save_button.pressed.connect(action_create_save)
	
	confirm_text_entry.pressed.connect(action_confirm_text_entry)
	cancel_text_entry.pressed.connect(action_cancel_text_entry)
	delete_button.pressed.connect(action_delete)
	
	text_entry.text_changed.connect(validate_name)
	selection_changed()

func validate_name(value: String):
	confirm_text_entry.disabled = !value.is_valid_filename()

func action_delete():
	if delete_timeout > 0.0:
		var path = tree.get_selected().get_metadata(0)["path"]
		OS.move_to_trash(ProjectSettings.globalize_path(path)) 
		delete_timeout = -1.0
		refresh()
	else:
		delete_timeout = 0.5
func action_create_save():
	action = "save"
	text_entry_root.show()
	text_entry.text = ""
	text_entry_label.text = "Name your Save File"
	text_entry.placeholder_text = "Save File Name"
func action_create_category():
	action = "category"
	text_entry_root.show()
	text_entry.text = ""
	text_entry_label.text = "Name your Folder"
	text_entry.placeholder_text = "Folder Name"
func action_cancel_text_entry():
	text_entry.text = ""
	text_entry_root.hide()
func action_confirm_text_entry():
	var path = tree.get_selected().get_metadata(0)["path"]
	if action == "save":
		DirAccess.make_dir_absolute(path+"/save_"+text_entry.text)
	if action == "category":
		DirAccess.make_dir_absolute(path+"/category_"+text_entry.text)
	text_entry_root.hide()
	refresh()
func selection_changed():
	var item = tree.get_selected()
	var is_save: bool = item.get_metadata(0)["is_save"]
	var path: String = item.get_metadata(0)["path"]
	create_category_button.disabled = is_save
	create_save_button.disabled = is_save
	load_button.disabled = !is_save
	delete_button.disabled = item == tree.get_root()

func refresh():
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "📁 Saves")
	root.set_metadata(0, {
		path = "user://",
		is_save = false
	})
	_explore_folder(root, "user://")
	note.info("Refreshing save tree")
	tree.get_root().select(0)
func tree_confirm():
	load_save(tree.get_selected().get_metadata(0)["path"])

func load_save(path: String, skip_animation: bool = false):
	var is_dev = false
	var paths: PackedStringArray = path.split("/")
	if len(paths) > 0:
		var real_save_name = paths[-1].substr(5)
		is_dev = real_save_name.begins_with(ProjectSettings.get_setting("addons/note/dev/prefix", "__"))
	
	var SessionType = load(ProjectSettings.get_setting("addons/note/save_session_type", note.default_save_session))
	var new_session: NoteSaveSession = SessionType.new(path, is_dev) as NoteSaveSession
	if new_session == null:
		push_error("Failed to load session type, is your `Addons/Note/Save Session Type` a descendant of NoteSaveSession?")
	note.current_session = new_session
	if sticky:
		var data = {
			"save_path": path,
			"save_stuck": true
		}
		var target = FileAccess.open("user://_note.json", FileAccess.WRITE)
		target.store_string(JSON.stringify(data))
		target.close()
	var init_path: String
	var dev_path = ProjectSettings.get_setting("addons/note/dev/dev_entry_point", "")
	if note.current_session.is_dev() and dev_path != "":
		note.info("Developer entry point in use")
		init_path = dev_path
	else:
		init_path =  ProjectSettings.get_setting("addons/note/user/entry_point", "")
	
	if init_path != "":
		if skip_animation:
			get_tree().call_deferred("change_scene_to_file", init_path)
		else:
			note.load_level_with_loading_screen(init_path, 0.33)

func _process(delta: float) -> void:
	if delete_timeout >= 0.0:
		delete_timeout -= delta
		delete_button.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(Color(1.0, 0.3, 0.3, 1.0), delete_timeout/0.5)
		if delete_timeout <= 0.0:
			delete_timeout = -1.0
			note.popup.send("[b]Double click[/b] to delete things.")
	else:
		delete_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

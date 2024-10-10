extends Node
class_name NoteEntryPoint

var first_time: bool = false

func _ready() -> void:
	if exists("_note_stuff"):
		var data: Dictionary = read_object("_note_stuff")
		if data.has("first_time_setup_required"):
			first_time = data["first_time_setup_required"]
	else:
		var default_data = {
			"first_time_setup_required" = false
		}
		write_object("_note_stuff", default_data)
		first_time = true
	starting()


func is_dev() -> bool:
	return note._current_save_dev
## Checks if the resource(whether in subdirectory or save file root) exists.
## Does not check the file type, so will check if the resource exists whether its
## json or tres.
func exists(resource_name: String) -> bool:
	var stages: Array = resource_name.split("/")
	var target_file = stages.pop_back()
	var target_folder:String = "" 
	
	if len(stages) > 0:
		target_folder = note._current_save+"/"+"/".join(stages)
	else:
		target_folder = note._current_save
	
	if DirAccess.dir_exists_absolute(target_folder):
		var file_list: Array = DirAccess.get_files_at(target_folder)
		for file: String in file_list:
			if file.get_slice(".", 0) == target_file:
				return true
	return false
## Ensures that a chain of subdirectories exist inside of your save folder.
## This is already relative to your save folder.
func ensure_subdirectory(subdir: String):
	DirAccess.make_dir_recursive_absolute(note._current_save+"/"+subdir)
## Takes a resource and saves it inside your save folder.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func write_resource(resource_name: String, resource: Resource):
	ResourceSaver.save(resource, note._current_save+"/"+resource_name+".tres")
## Takes a dictionary and saves it inside your save folder as json.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func write_object(resource_name: String, object: Dictionary):
	var file = FileAccess.open(note._current_save+"/"+resource_name+".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(object))
	file.close()
## Finds the resource inside your save folder and turns it into the resource it was.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
## NOTE: Using this for saves is potentially unsafe, as third party saves could include arbitrary code execution.
func read_resource(resource_name: String) -> Resource:
	return ResourceLoader.load(note._current_save+"/"+resource_name+".tres")
## Finds the json inside your save folder and turns it into the dictionary it was.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func read_object(resource_name:String) -> Dictionary:
	var file = FileAccess.open(note._current_save+"/"+resource_name+".json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data
func is_first_time() -> bool:
	return first_time

## Called when the save is starting, do your save loading here
func starting():
	pass
## Called when the save is exiting. Either by game closing, or by "return to save selection"
func ending():
	pass
## Called every so often by note as a heartbeat while this is on the shelf.
## Useful for tracking an autosave or sending events to the game such as an
## Auto-save indicator.
func pulse(time_since_last_pulse: float):
	pass

## Call this when you're done loading.
func done(next_scene: PackedScene):
	note._manager = note.swap_level(next_scene)
	if ProjectSettings.get_setting("addons/note/user/keep_entry_in_tree", false):
		get_tree().root.add_child(note._manager)

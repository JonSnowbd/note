extends Node
class_name NoteSaveSession

signal unloading

var save_path: String
var is_save_developer: bool = false
var is_save_first_time: bool = false

func _init(path: String, is_developer: bool) -> void:
	save_path = path
	is_save_developer = is_developer
	
	if is_save_developer:
		note.info("Save "+path+" loaded as a developer.")
	
	if exists("note_meta"):
		var data: Dictionary = read_object("note_meta")
		is_save_first_time = data["first_time"]
	else:
		var default_data = {
			"first_time" = false,
		}
		write_object("note_meta", default_data)
		is_save_first_time = true
	
	starting()
## If this save was named with the developer prefix at the start, this session
## is a developer session.
func is_dev() -> bool:
	return is_save_developer
## Checks if the file name(whether in subdirectory or save file root) exists.
## Does not check the file type, so will check if the file exists whether its
## json or tres.
func exists(resource_name: String) -> bool:
	var stages: Array = resource_name.split("/")
	var target_file = stages.pop_back()
	var target_folder:String = "" 
	
	if len(stages) > 0:
		target_folder = save_path+"/"+("/".join(stages))
	else:
		target_folder = save_path
	
	if DirAccess.dir_exists_absolute(target_folder):
		var file_list: Array = DirAccess.get_files_at(target_folder)
		for file: String in file_list:
			if file.get_slice(".", 0) == target_file:
				return true
	return false
## Ensures that a chain of subdirectories exist inside of your save folder.
## This is already relative to your save folder. e.g `ensure_subdirectory("your/folder/chain")`
func ensure_subdirectory(subdir: String):
	DirAccess.make_dir_recursive_absolute(save_path+"/"+subdir)
## Takes a resource and saves it inside your save folder.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func write_resource(resource_name: String, resource: Resource):
	ResourceSaver.save(resource, save_path+"/"+resource_name+".tres")
## Takes a dictionary and saves it inside your save folder as json.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func write_object(resource_name: String, object: Dictionary):
	var file = FileAccess.open(save_path+"/"+resource_name+".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(object))
	file.close()
## Finds the resource inside your save folder and turns it into the resource it was.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
## NOTE: Using this for saves is potentially unsafe, as third party saves could include arbitrary scripts.
func read_resource(resource_name: String) -> Resource:
	return ResourceLoader.load(save_path+"/"+resource_name+".tres")
## Finds the json inside your save folder and turns it into the dictionary it was.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func read_object(resource_name:String) -> Dictionary:
	var file = FileAccess.open(save_path+"/"+resource_name+".json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data
## Reads a file as a string. This does not include the file type, so include this in the parameter.
func read_file(file_name: String) -> String:
	var file = FileAccess.open(save_path+"/"+file_name, FileAccess.READ)
	var data = file.get_as_text()
	file.close()
	return data
## File operations must include the file type. Opens a file inside the save and returns it.
func open_file(file_name: String) -> FileAccess:
	var file = FileAccess.open(save_path+"/"+file_name, FileAccess.READ)
	return file
## Returns true if this is either a new save, or a re-first was requested.
func is_first_time() -> bool:
	return is_save_first_time

func starting():
	pass
func ending():
	pass
func pulse(time_since_last_pulse: float):
	pass

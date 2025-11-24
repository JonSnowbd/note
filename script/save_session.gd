extends Node
class_name NoteSaveSession

signal unloading

## The base folder for the save.
var save_path: String
## If true, this save's profile name begins with the developer prefix.
var is_save_developer: bool = false
## If true, this is the first time a save is being used.
var is_save_first_time: bool = false

## Internal context variable, do not use this for anything.
var current_path: String

func _init(path: String, consume_first_time: bool = true) -> void:
	save_path = path
	set_context_save()
	if consume_first_time and exists("first_timer_indicator"):
		is_save_first_time = true
		delete_file("first_timer_indicator")

## Abstract: Called when everythings in place for you to start loading profile data.
## Implement loading here. Check out the github for the list of loading functions.
func starting():
	pass
## Abstract: Called when ending session, implement saving here.
## Check out the github for the list of loading functions.
func ending():
	pass
## Virtual: do background pulse checks here. eg ticking up time for an autosave
func pulse(time_since_last_pulse: float):
	pass
## [b]Optional[/b]: Return a control that overwrites the save pill's face
## plate used in profile. This would be the label by default, keeping the menu dropdown
## and select button. Use this if your saves have selected characters/progress/user names
## you'd like to reflect in their thumbnail.
## NOTE: The save is not fully saturated when this is called, so try to keep this thin, and
## not dependant on [code]starting()[/code]
func get_fancy_pill() -> Control:
	return null

## Calling this makes calls through the save api relative to the current save
## folder.
func set_context_save():
	current_path = save_path+"/"
## Calling this makes calls through the save api relative to the root
## of the user folder.[br]
## [code]set_context_global()
## exists("your_file.txt") # This is looked for in user://
## set_context_save()
## exists("your_file.txt") # This is looked for in the save folder.[/code]
func set_context_global():
	current_path = "user://"

## Checks if the file name(whether in subdirectory or save file root) exists.
## Does not check the file type, so will check if the file exists whether its
## json or tres.
func exists(resource_name: String) -> bool:
	var stages: Array = resource_name.split("/")
	var target_file = stages.pop_back()
	var target_folder:String = "" 
	
	if len(stages) > 0:
		target_folder = current_path+("/".join(stages))
	else:
		target_folder = current_path
	
	if DirAccess.dir_exists_absolute(target_folder):
		var file_list: Array = DirAccess.get_files_at(target_folder)
		for file: String in file_list:
			if file.get_slice(".", 0) == target_file:
				return true
	return false

## Ensures that a chain of subdirectories exist inside of your save folder.
## This is already relative to your save folder. e.g `ensure_subdirectory("your/folder/chain")`
func ensure_subdirectory(subdir: String):
	DirAccess.make_dir_recursive_absolute(current_path+subdir)

## Takes a resource and saves it inside your save folder.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func write_resource(resource_name: String, resource: Resource):
	ResourceSaver.save(resource, current_path+resource_name+".tres")

## Takes a dictionary and saves it inside your save folder as json.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func write_object(resource_name: String, object: Dictionary):
	var file = FileAccess.open(current_path+resource_name+".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(object))
	file.close()

## Writes a texture to the save folder, do not include the file type. Saves the texture to
## png if quality >= 1.0 and jpg when < 1.0 with the jpg quality set to quality. Note, 
## quality < 1.0 means transparency will be discarded.
func write_texture(texture_name: String, texture: Texture2D, quality: float = 1.0):
	var img = texture.get_image()
	if quality < 1.0:
		img.save_jpg(current_path+texture_name+".jpg", quality)
	else:
		img.save_png(current_path+texture_name+".png")

## Reads a texture from the save folder, do not include the file type.
func read_texture(texture_name) -> Texture2D:
	var png_path = current_path+texture_name+".png"
	var jpg_path = current_path+texture_name+".jpg"
	if FileAccess.file_exists(png_path):
		var img = Image.load_from_file(png_path)
		return ImageTexture.create_from_image(img)
	if FileAccess.file_exists(jpg_path):
		var img = Image.load_from_file(jpg_path)
		return ImageTexture.create_from_image(img)
	return null

## Finds the resource inside your save folder and turns it into the resource it was.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
## NOTE: Using this for saves is potentially unsafe, as third party saves could include arbitrary scripts.
func read_resource(resource_name: String) -> Resource:
	return ResourceLoader.load(current_path+resource_name+".tres")

## Finds the json inside your save folder and turns it into the dictionary it was.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func read_object(resource_name:String) -> Dictionary:
	var file = FileAccess.open(current_path+resource_name+".json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

## Reads a file as a string. This does not include the file type, so include this in the parameter.
func read_file(file_name: String) -> String:
	var file = FileAccess.open(current_path+file_name, FileAccess.READ)
	var data = file.get_as_text()
	file.close()
	return data

## File operations must include the file type. Opens a file inside the save and returns it.
func open_file(file_name: String) -> FileAccess:
	var file = FileAccess.open(current_path+file_name, FileAccess.READ_WRITE)
	return file

## File operations must include the file type. Deletes a file inside the save.
func delete_file(file_name: String):
	DirAccess.remove_absolute(current_path+file_name)

## Returns true if this is either a new save, or a re-first was requested.
func is_first_time() -> bool:
	return is_save_first_time

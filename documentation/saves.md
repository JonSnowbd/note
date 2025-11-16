# Save Files

By extending `NoteSaveSession` you already have what you need to provide Note with your
save structure. Simply put the script in your Note Developer Settings under the save category
as `Session Type`.

## Methods

In `starting()` and `ending()` you load and save your game using the following functions:

```
## Checks if the file name(whether in subdirectory or save file root) exists.
## Does not check the file type, so will check if the file exists whether its
## json or tres.
func exists(resource_name: String) -> bool
## Ensures that a chain of subdirectories exist inside of your save folder.
## This is already relative to your save folder. e.g `ensure_subdirectory("your/folder/chain")`
func ensure_subdirectory(subdir: String)

## Takes a resource and saves it inside your save folder.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func write_resource(resource_name: String, resource: Resource)

## Takes a dictionary and saves it inside your save folder as json.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func write_object(resource_name: String, object: Dictionary)

## Writes a texture to the save folder, do not include the file type. Saves the texture to
## png if quality >= 1.0 and jpg when < 1.0 with the jpg quality set to quality.
func write_texture(texture_name: String, texture: Texture2D, quality: float = 1.0)

## Reads a texture from the save folder, do not include the file type.
func read_texture(texture_name) -> Texture2D

## Finds the resource inside your save folder and turns it into the resource it was.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
## NOTE: Using this for saves is potentially unsafe, as third party saves could include arbitrary scripts.
func read_resource(resource_name: String) -> Resource

## Finds the json inside your save folder and turns it into the dictionary it was.
## This is already relative to your save folder, and will include the appropriate file type.
## So use just the name, eg "misc/stats" or "profile"
func read_object(resource_name:String) -> Dictionary

## Reads a file as a string. This does not include the file type, so include this in the parameter.
func read_file(file_name: String) -> String
## File operations must include the file type. Opens a file inside the save and returns it.
func open_file(file_name: String) -> FileAccess
## File operations must include the file type. Deletes a file inside the save.
func delete_file(file_name: String)
```

I recommend using `*_object`(json) methods for 99% of your loading as resource loading can harbour
built in scripts for arbitrary code execution via save sharing.

This should include settings and save-file related data such as selected character, current map
, unlocked skills, etc.

If you have cross-save data that you want to load, you can swap the context that the read/write
files operate in with the following methods

```gdscript
## Calling this makes calls through the save api relative to the current save
## folder.
func set_context_save()
## Calling this makes calls through the save api relative to the root
## of the user folder.
func set_context_global()
```

When the context is save, read/write/exists look for a file inside of the save profile folder,
and when the context is global, read/write/exists looks for a file inside of `user://`.

## Save File Dev Settings

- **Strategy** is where you set Simple(instant non-changeable save profile) or Profile Selector(start
the game into a profile selection screen)
- **Session Type** is the script file you made that extends `NoteSaveSession`
- Sticky is a feature for profile selector, where after picking or creating a save, the user
is automatically logged into that save every startup until they manually go back to save selection
via `note.return_to_save_select()`
- **Soft settings** is not working yet, but will save general settings such as volumes, fullscreen,
window position/size, and restore them each time your game launches. It will be recommended
for extremely quick/small games that don't want to bother with a save file.
- **Pulse Duration** determines the interval at which your save file receives the 'heartbeat' type method
called `pulse(time: float)`

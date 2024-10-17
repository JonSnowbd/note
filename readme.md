## Note

Note is an opinionated 'game launcher' that will handle your game for you
so you only need to write some code that reads/writes and launches your initial scene.
With that note then handles:
- Creating, loading, deleting of saves, and save folders.
- Transitioning from scene to scene with animated transitions
- Loading scenes with a loading screen to avoid hangups

And provides the following features:
- More detailed info/warn/error logging with a dedicated error scene
- Control instruction gui, and resources that ease the input -> icon process
- System message gui, completely customizable.
- Immediate mode tooltip system resistant to infrequent calls, and priority system for overlaps.
- Utility class with a good amount of features. Including a nice

Tested and built against the development of one game, soon to be two to nail the finer points.

[See the credit list for assets used. Licenses used by assets ]

### Development

Note is in development. Things that are missing that I intend to implement:
- Playstation/Steam deck/Nintendo/generic icons in the icon resource
- More transition shaders.

### Why note?

Being an opinionated plugin that intends to take away some amount of freedom from the user, the benefits
I hope for some will be considered worth it! 

### I need...

Open an issue, if the requirement is easy to lift into an exported variable or project setting,
I am completely open to making that change. New features I'm hesitant, but if like tooltip/sys message/control guide
it is something seen in every game, I'm open to adding it to note.

## Guide

### Integration

To use note it is recommended to integrate note into Godot. This lets note do
some stuff for you such as managing saves, save folders, and loading/unloading
the save, and starting your game for you.

- Set your godot project's entry scene to `res://addons/note/ENTRY_SCENE.tscn`
- Create a scene that has an `NoteEntryPoint` extended class at the root of it (More on what you do in there in the Game Init category)
- Set that scene in Project Settings: `Addons/Note/User/Entry Point`

Now when your game starts it note will let the user decide which save they wish to use


### Game Init

Your game init exists for the duration of your game, its persisted as a manager in note. Note does not provide
a way to get your manager from anywhere, if this is desired, you should use the built in Note service provider.

Here is an example of a game init script from one of my games.

```gdscript

extends NoteEntryPoint
class_name SwingInit

# This init script is a logo reveal 

@export var animator: AnimationPlayer
@export var next_scene: PackedScene

var save: Save

func starting() -> void:
	if exists("profile"):
		save = read_resource("profile")
	else:
		save = Save.new()
		write_resource("profile", save)
	note.designate_service(Save, save)
	note.designate_service(SwingInit, self)
	save.update_changes_to_audio()
	save.update_changes_to_graphics()
	animator.animation_finished.connect(done)
func ending() -> void:
	write_resource("profile", note.locate_service(Save))
	note.destroy_service(Save, save)
	note.destroy_service(SwingInit, self)
	save = null

func set_dev():
	first_time_scene = dev_scene
	regular_scene = dev_scene

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_F1):
		set_dev()

```

<p align="center">
  <img src="/documentation/logo.png" />
</p>
<h1 align="center"> Note</h1>

Note is a simple shim. By loading the Note entry scene first, and defining
a settings file you get a buttload of dev QoL features and nodes at the cost
of slight freedom in the initialization of your app.

For trading off some installation time and learning how to structure a save file(it's
easy, I promise!) you get:

- Very flexible and customizable transition system that lets you trigger
a transition anywhere anytime, even outside of loading a new level or changing view.
- Simple Mouse+Keyboard and Gamepad coexistance with logic nodes to help organize
very clean gamepad UI interactions.
- Automatic loading behaviours including loading screen and level changer, that all
work together to make your game seamless, and handle better practices for you, such as
asynchronous loading screens, and background pre-loading.
- A new Godot tab with goodies such as a GDScript playground, a Note help page, and more
to come.
- An organized logic chain system for orchestrating your game interactions.
- A collection of very commonplace UI Elements ready to use out of the box, such as
control guides and tooltips.
- Oh, and an extremely easy and convenient way to modify your types to have custom editors.
Realizing I could do this in Note and never have to make a EditorInspectorPlugin again was really fun.
- And lots of standalone node types and utility functions that cover, and much more.

---

## Project Status

> [!CAUTION]
> Note tracks with **Godot 4.6 Dev** cycle, awaiting Traits before settling on Stable.
Traits will be used extensively for some Note features and as such will be in flux prior to,
and during the Traits dev release.

I'm using Note right now to develop a game, and I'm adding new features and fixing bugs
as I go, and as such I don't recommend using it just yet unless you're cool with breaking
changes happening quite often as I distill Note into something even more ergonomic.

With that said, I will be doing my best to maintain documentation going forward so you're never
lost while using Note. It's also worth mentioning that after you make your save file and settings file,
Note gets out of your way real quick so you should not be blocked by Note breaking changes often.

---

## Install

> [!NOTE]
> If you are experienced with installing Godot plugins, you can skip to the end of this
category and read the last few steps! It's nothing new besides the use of a settings
file in your project settings.

<details>

<summary>
In your Godot project use <code>git submodule add https://github.com/JonSnowbd/note addons/note</code>
(If this fails make sure your project is a git repo with <code>git init</code>) OR clone this repo and
place it in your <code>YOUR_PROJECT/addons/</code> folder.
</summary>

![Screenshot of your godot folder after the above commands](/documentation/post_install.png)

</details>

<details>

<summary>In your project settings enable Note</summary>

![Enabling note in your project settings](/documentation/enabling_note.png)

</details>

<details>

<summary>
And then create a Note Developer Settings file in your project. Note will automatically
find it and set the settings file to be the default one. If you want to change the settings
file that note uses, you can change or set it manually in <code>ProjectSettings/Addons/Note</code>
</summary>

![Creating your Note developer file](/documentation/creating_settings.png)

</details>

<details>

<summary>
Finally in your Project Settings set the main scene to Note's entry,
and your games main scene to the settings file initial scene. You're done!
</summary>

![Setting the entry scenes up.](/documentation/setting_entry_points.png)

</details>

## Your Integration Checklist

- [ ] Add the `note` folder to `YOUR_PROJECT/addons/`
- [ ] Enable `note` in Project Settings
- [ ] Create a `NoteDeveloperSettings` resource in your project for Note to automatically
detect(or set it manually in `ProjectSettings/Addons/Note`)
- [ ] Set your Entry Scene to `res://addons/note/ENTRY.tscn`
- [ ] Set your real game's entry scene in your `NoteDeveloperSettings` file.
- [ ] **(Optional)** Create a custom Save Script and set it in your Developer Settings
- [ ] **(Optional)** ... Enjoy!

## Setup

After doing all that, theres a few things you can do to customize your
Note experience. By default note uses the simple profile approach to saves,
which means `save_simple` profile is created and instantly loaded on game start.
You can opt to instead offer a profile selector in your note settings file, labelled 
`Save Strategy`, so you can let the user swap between many save files.

After choosing Simple vs Selector strategy, you just need to create a save script
to 'finish' your setup. It is optional but highly recommended if you want your game
to have saving and loading persistent data.

In your save script all you need to do is handle loading and saving that specific data,
and optionally exposing a control to use in the profile selector's face plate.

```gdscript
extends NoteSaveSession
class_name YourGameSaveType

var volume: float
var fullscreen: bool
var character_name: String

# Load all the data here
func starting():
	var json = {}
	if exists("user_data"):
		json = read_object("user_data")
	volume = json.get_or_add("volume", 0.1)
	fullscreen = json.get_or_add("fullscreen", false)
	character_name = json.get_or_add("character_name", "Roger")
	
	note.util.set_volume("Master", volume)
	if fullscreen:
		note.util.set_fullscreen(note.util.FullscreenState.BorderlessFullscreen)
	else:
		note.util.set_fullscreen(note.util.FullscreenState.Windowed)

# Save all the data here
func ending():
	write_object("user_data", {
		"volume" = volume,
		"fullscreen" = fullscreen,
		"character_name" = character_name
	})

# Return a custom control for the save profile to show.
# You might want to include playtime, character name, last saved
# date, level, story progress etc. here.
func get_fancy_pill() -> Control:
	# This function is called raw before starting, so load the relevant info
	# Beforehand
	if exists("user_data"):
		var info = read_object("user_data")
		var label = Label.new()
		label.text = info.get_or_add("character_name", "Roger")
		return label
	return null
```

Here is a really simple example of a save type.

It may look like a lot at first, but its way simpler than it looks.
Basically in `starting` you check if things `exists`, and `read_*` them to fill up your settings,
being wary that they might not exist and providing safe default.

In `ending` you `write_*` things to disk.

in `get_fancy_pill` you create a control that represents your save files profile plate.

Here is a list of save file qol methods you can use, these methods already adapt file paths
to be relative to the save file folder, so you don't even need to think about that. 

```gdscript
# checks if "file" exists, no matter the filetype.
exists("file") -> bool

# Don't include filetype. looks for "file.json" and reads/writes it into a dictionary.
read_object("file") -> Dictionary
write_object("file", {"data" = 10.0})

# Don't include filetype. looks for "file.tres" and reads/writes it into a dictionary.
# Note this can be a security issue if you use these in your saves.
read_resource("file") -> Resource
write_resource("file", resource)

# Include filetype. looks for "file.txt" and reads it into a String, and opens
# a FileAccess session when opening one.
read_file("file.txt") -> String
open_file("file.txt") -> FileAccess
delete_file("file.txt")
```


## Tidbits

Here is a general overview for some of the juicy functions you might want to use
in your game from anywhere. Note has many features that are more indepth,
and this list only includes method calls, so peek at the docs below for the standalone
nodes and traits.

```gdscript
note.save as YourSaveType
# VERY HANDY! I recommend interacting with your save like this
# to do things such as read unlocked items for your UIs, or
# figure out which level to resume at, or even expose
# settings changing methods in your save type. Such as update_fullscreen_mode


note.util.set_fullscreen(flag: note.util.FullscreenState)
note.util.set_volume(linear_volume: float) # 0.0-1.0 expected, but below and above are valid.

note.info(message: String, custom_header: String?) # Custom header optional. Make your prints look like Note's, and get bbcodes aswell.
note.warn(message: String, custom_header: String?) #
note.stack_trace(message: String) # Prints out your message, as well as a stack trace.
note.error(message: String) # Prints out your message, in bright error red with stack trace.
note.time(header: String) # Call once with the name of the section you're timing, then again after with no parameter to finish the timer.

note.execute(script_file) # Takes many things, and runs the script if its a NoteGameScript

note.return_to_save_select() # calls level.change_to back to the profile selector and unsticks a stuck save.

note.phase.begin(id) -> Variant # ID Can be the script, name, path, uid, or class_name of the phase you registered in your settings file.
note.phase.begin_instant(id) -> Variant # Like above but without a fade-in animation
note.phase.end(id) # Fades out the current phase, leaving nothing
note.phase.end_instant(id)

note.level.change_to(path_or_packed_scene, with_load_screen: bool = false)
note.level.swap(path_or_packed_scene, with_load_screen: bool = false) -> Variant # Returns the old level rather than deleting it.
```

## Doc Guides

Note is intentionally designed to be taken on in bits as you integrate however much you
want into your project. Give each doc a small read over to understand what each part of Note
could do for you and keep them in mind, odds are if you remember Note could do it for you, you end
up saving hours from writing your own systems.

- [Phases](/documentation/phases.md) RECOMMENDED! These don't get mentioned here but its a very beneficial
design pattern, which I added due to missing something similar from Unreal Engine.
- [Save files in depth](/documentation/saves.md) RECOMMENDED
- [Transitions](/documentation/transitions.md)


## Credits

Note wouldnt be what it is without the open source/MIT projects it stands on:

- https://kenney.nl/assets/input-prompts
- https://kenney.nl/assets/ui-audio
- https://gl-transitions.com
- https://www.svgrepo.com/collection/denali-solid-interface-icons
- https://fonts.google.com/specimen/Outfit
- https://github.com/binogure-studio/godot-uuid/tree/master

(These are packaged up already, you do not need to install these dependencies!)

## License

Note uses the MIT License as noted in the license file.
Feel free to do whatever you want with it!

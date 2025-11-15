# <span><img src="documentation/logo.png"/> Note.gd</span>

Note is a simple shim. By loading the Note entry scene first, and defining
a settings file you get a buttload of dev QoL features and nodes at the cost
of slight freedom in the initialization of your app.

For trading off some installation time and learning how to structure a save file(it's
easy, I promise!) you get:

1) Very flexible and customizable transition system that lets you trigger
a transition anywhere anytime, even outside of loading a new level or changing view.
2) Simple Mouse+Keyboard and Gamepad coexistance with logic nodes to help organize
very clean gamepad UI interactions.
3) Automatic loading behaviours including loading screen and level changer, that all
work together to make your game seamless, and handle better practices for you, such as
asynchronous loading screens, and background pre-loading.
4) A new Godot tab with goodies such as a GDScript playground, a Note help page, and more
to come.
5) An organized logic chain system for orchestrating your game interactions.
6) A collection of very commonplace UI Elements ready to use out of the box, such as
control guides and tooltips.
7) Oh, and an extremely easy and convenient way to modify your types to have custom editors.
Realizing I could do this in Note and never have to make a EditorInspectorPlugin again was really fun.
8) And lots of standalone node types and utility functions that cover, and much more.

## Project Status

I'm using Note right now to develop a game, and I'm adding new features and fixing bugs
as I go, and as such I don't recommend using it just yet unless you're cool with breaking
changes happening quite often as I distill Note into something even more ergonomic.

Note tracks with **Godot 4.6 Dev** cycle, awaiting Traits before settling on Stable.
Traits will be used extensively for some Note features and as such will be in flux prior to,
and during the Traits dev release.

With that said, I will be doing my best to maintain documentation going forward so you're never
lost while using Note. It's also worth mentioning that after you make your save file and settings file,
Note gets out of your way real quick so you should not be blocked by Note breaking changes often.

## Install

(If you are experienced with installing Godot plugins, you can skip to the end of this
category and read the last few steps! It's nothing new besides the use of a settings
file in your project settings.)

- In your Godot project use `git submodule add https://github.com/JonSnowbd/note addons/note` 
(If this fails make sure your project is a git repo with `git init`)
- OR clone this repo and place it in your `YOURPROJECT/addons/` folder. But really I recommend
using git above
- So your Godot project now has `addons/note` like so:
![Screenshot of your godot folder after the above commands](/documentation/post_install.png)

- In your project settings enable Note
![Enabling note in your project settings](/documentation/enabling_note.png)

- And then create a Note Developer Settings file in your project. Note will automatically
find it and set the settings file to be the default one. If you want to change the settings
file that note uses, you can change or set it manually in `ProjectSettings/Addons/Note`
![Creating your Note developer file](/documentation/creating_settings.png)

- Finally in your Project Settings set the main scene to Note's entry,
and your games main scene to the settings file initial scene. You're done!
![Setting the entry scenes up.](/documentation/setting_entry_points.png)

## Setup

After doing all that, theres a few things you can do to customize your
Note experience. By default note uses the simple profile approach to saves,
which means `save_simple` profile is created and instantly loaded on game start.
You can opt to instead offer a profile selector in your note settings file, so
you can let the user swap between many save files.

After choosing Simple vs Selector strategy, you just need to create a save script
to 'finish' your setup.

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

## Your Integration Checklist

- [ ] Add the `note` folder to `YOUR_PROJECT/addons/`
- [ ] Enable `note` in Project Settings
- [ ] Create a `NoteDeveloperSettings` resource in your project for Note to automatically
detect(or set it manually in `ProjectSettings/Addons/Note`)
- [ ] Set your Entry Scene to `res://addons/note/ENTRY.tscn`
- [ ] Set your real game's entry scene in your `NoteDeveloperSettings` file.
- [ ] **(Optional)**

## Overview

Here is a general overview of the juicy functions you want to use
in your game from anywhere. Note has many features that are more indepth,
and this list only includes method calls, so peek at the docs below for the standalone
nodes and traits.

```gdscript
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



```

## Doc Guides

Note is intentionally designed to be taken on in bits as you integrate however much you
want into your project. Give each doc a small read over to understand what each part of Note
could do for you and keep them in mind, odds are if you remember Note could do it for you, you end
up saving hours from writing your own systems.

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

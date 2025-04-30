# Note

Note is an opinionated 'game launcher' that will handle your game for you
so you only need to write some code that reads/writes and launches your initial scene.
With that note then handles:
- Creating, loading, deleting of saves, and save folders.
- Transitioning from scene to scene with animated transitions
- Loading scenes with a loading screen to avoid hangups

And provides the following features:
- Gamepad UI control adapter and amazing control over Gamepad/MKB unified
UI
- More detailed info/warn/error logging with a dedicated error scene
- Control instruction gui, and resources that ease the input -> icon process
- System message gui, completely customizable.
- Immediate mode tooltip system resistant to infrequent calls, and priority system for overlaps.
- A control/UI abstraction similar to Unreal's Player Controller
- Utility class with a good amount of features.

See the credit list for assets used/included.

### Development

Note is in active development, it is very usable for games, but please avoid using this
library for production if you are not ready to deal with a changing api, and potential bugs.

Note is currently being developed against a personal project.

### Why note?

Being an opinionated plugin that intends to take away some amount of freedom from the user, it is good to know up front what Note expects from you.

Personally I use this in all my projects to great enjoyment of the QoL
of not needing to implement many of the features that Note handles for you

By using Note you lose the full control of 'owning' the initial scene,
as Note will have a loading segment before your game is shown. This
shouldn't be too much of an issue for a vast majority of cases.

Note features are designed around games that will start in
windowed mode, and do not use a forced aspect ratio/resolution(Note
has tools that will do this for you, in game rather than in the final render target). Any side effects for not following these assumptions will be minor,
but noticeable.
Swapping to fullscreen during the save session load is the preferred
solution, as windowed to fullscreen is more visually acceptable than
full screen to windowed.

### I need...

Open an issue, if the requirement is easy to lift into an exported variable or project setting,
I am completely open to making that change. New features I'm hesitant, but if like tooltip/sys message/control guide
it is something seen in every game, I'm open to adding it to note.

## Guide

### Integration

To use note it is recommended to integrate note into Godot. This lets note do
some stuff for you such as managing saves, save folders, and loading/unloading
the save, and starting your game for you.

- Set your godot project's entry scene to `res://addons/note/ENTRY_MULTISAVE.tscn` or `res://addons/note/ENTRY_SIMPLE.tscn`
- Set your initial scene in Project Settings: `Addons/Note/User/Entry Point`, this will be opened after a save is selected.
- Make sure note is the first autoload, as you add more to your game.

Now when your game starts, note will let the user decide which save they wish to
use(or a simple default save will be made or loaded if using simple), or autoload
the current sticky save, and then begin your game.


# System Overview

## Broad API

An overview of the most common note interactions you can take.

```gdscript
# If you're using multi-save entry point, place
# this in the main menu for your users. Returns to
# save select
note.return_to_save_select()

# If you're using multi-save entry point, and sticky
# saves then this will unstick 
note.unstick_save()

# Calls in a temporary ColorRect that covers the entire screen
# good QoL for things like covering an outfit change.
note.temporary_blackout(in_time: float, duration: float, out_time: float, color: Color)

# Screenshots the current screen, and begins the transition animation.
# This wont change the level, just a seamless snapshot in the viewport
# fading to the current viewport. To emulate a load_level call,
# call this, and then change scene. The previous frame will cover the
# seam. This is used during all the load/swap levels if transition time
# is >0.0
note.transition(duration: float)

# A wide suite of calls that can manipulate the current scene.
# Any function that changes the level will also call transition
# to hide the seam in gameplay.

# These simply change to a loaded scene. 
# Swap will return, load will delete it.
note.swap_level(scene: PackedScene, transition_time: float?) -> Node
note.load_level(scene: PackedScene, transition_time: float?)

# These are like the above, but takes a string path to the res://
# and use a loading screen with asynch loading for better performance
# without a large load. Prefer to use these in your game
# to prevent chain preloading every level into one resource.
note.swap_level_with_loading_screen(scene: String, transition_time: float?) -> Node
note.load_level_with_loading_screen(scene: String, transition_time: float?)

# Marks a service with an identifier. Object is placed in a service stack,
# where the most recent one has priority.
note.designate_service(identifier, object: Object)
# Removes the service under identifier.
note.destroy_service(identifier, object: Object)
# Retrieves the most recent service under identifier.
note.locate_service(identifier) -> Object


# Adds a subscriber to any event that goes through note
# where the first parameter is equal to the first parameter of send.
# the subscriber MUST have a _event(evt, data = null) function
note.listen(event_type, subscriber: Object)
# Same as above, except unsubscribes
note.unlisten(event_type, subscriber: Object)
# Sends an event to everything subscribed to events that == event_type
note.send(event_type, data: Variant?)

# Transitions are done with a full screen texture rect. This changes
# the transition at runtime. Prefer to use note's project settings
# to change the transition material if you do not need to do this during gameplay.
# prog_name is the uniform float in the material that will transition
# from 0.0 to 1.0 over the transition. By default this is "progress"
note.set_transition(shader: ShaderMaterial, prog_name: String?)

# A simple structured/pretty print. Header is optional, simply changes the
# keyword in front of the print.
note.info(message: String, header: String?)
note.warn(message: String, header: String?)

# A simple crash that moves to an error screen, printing
# the stack trace.
note.error(message: String)

# Note features a robust gamepad ui control scheme. If you disable
# note's automatic controller detection, this is how you toggle it.
# Not needed if you are letting note automatically detect changes.
note.set_gamepad_mode(should_be_gamepad: bool)
```

## Signals

```gdscript
# Called when a save is loaded or changed.
note.save_changed()

# Called when the gamepad is used, or a keyboard/mouse action happens
# and auto-detection is on.
note.control_mode_changed()

# When using a loading screen transition, this is called periodically to let
# you know how the load is going.
note.loading_change(progress: float)
```

## Types

```gdscript
# An abstraction for complex buff interaction, simplifying it to
# a single function call per buff type.
AutoStateCalculator : RefCounted
AutoStateEffect : RefCounted

# The basis for your save games. Hold ALL user data in here, and
# the methods for loading/save your game, as well as general functions
# necessary for querying game state here.
NoteSaveSession : Node
```

## Core Mechanics

#### Events

```gdscript
extends Node2D

func _enter_tree():
	# Listen to all the event types you want
	note.listen(YourEventType, self)
	note.listen(OtherEventType, self)
func _exit_tree():
	# unlisten to any events you subscribe to for good performance
	# gains.
	note.unlisten(YourEventType, self)
	note.unlisten(OtherEventType, self)

## If you are listening to any events, this function
## is needed.
func _event(evt, data):
	# evt is the type of the event
	if evt == YourEventType:
		print("Hello!")

	# And if you set up events as the type, and the data
	# holder, you can do this:
	if data is YourEventType:
		print("Hello! This is also fine")

	# All subscribed events come through here, so check for each type.
	if data is OtherEventType:
		print("Nice!")

# And you can send events from anywhere, like this:
func _input(event):
	if event.is_action_pressed("confirm"):
		var evt = YourEventType.new()
		evt.data = self
		# The first parameter is the thing you subscribed to,
		# this is usually the type. then the data.
		note.send(YourEventType, evt)
```

#### Transitions

```gdscript
extends Area2D

## We use a string for loading screen loads,
## so levels aren't bloated by loading all references.
@export_file("*.tscn") var destination: String

func _ready():
	on_body_entered.connect(transfer)

func transfer(other):
	# The current scene is removed, the loading screen is
	# 
	note.load_level_with_loading_screen(destination)

	# See also:
	# note.load_level for loads that lock, or for preloaded assets.
	# note.swap_* for swap versions of each of these. 
	# (the unloaded level is returned instead of destroyed)
```

#### Services

Note has a service function to designate services that can be found anywhere
even if it exists outside of the tree.

```gdscriptwd
extends Node
class_name MechanicService

func _enter_tree():
	note.designate_service(MechanicService, self)
func _exit_tree():
	note.destroy_service(MechanicService, self)
```

and now can be accessed by `note.locate_service(MechanicService)` anywhere
else, as long as this lives.


## Autostate Calculator

An autostate calculator is very useful for important systems that you want to have
complicated interactions that can be modeled with a series of 'buffs' or 'effectors'.

#### Example Calculator

The calculator itself stores the data for effectors to mutate.

```gdscript
extends AutoStateCalculator
class_name StatCore

var armor: int = 0

var current_health: int = 50
var max_health: int = 50

var current_energy: float = 100.0
var max_energy: float = 100.0

## In the reset, you should have everything reset to default values.
## Note that you should model 'default stats' as a permanent effector,
## rather than having differing values for the default state.
func core_reset():
	max_health = 50
	current_health = 50
	armor = 0
	current_energy = 100.0
	max_energy = 100.0

## Intuitively create state queries, state when refreshed is stale only for a brief
## moment.
func is_dead() -> bool:
	return current_health <= 0
```

#### Example Effector

An effector applies a mutation to the calculator. The calculator, when refreshed,
will self-reset, then apply the effectors one by one. This is not as efficient
as writing your own  

```gdscript
extends AutoStateEffect
class_name DamageEffect

var source: Node
var amount: int = 0
var timestamp: int = 0

var powerful: bool = false

func _init(perpetrator: Node, damage: int) -> void:
	source = perpetrator
	amount = damage
	timestamp = Time.get_ticks_msec()

## Being a function that only needs to consider how to apply itself once
## no matter the other state, means managing interactions and querying/modifying buffs
## in realtime becomes extremely simple to maintain.
func apply(obj: AutoStateCalculator):
	if obj is StatCore:
		# Simply mutate the core, this will be applied each time the 
		obj.current_health -= amount
```

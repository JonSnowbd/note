# The Phase System

The phase system in note is a special gameplay abstraction similar to Unreal Engine's
`PlayerController` system, the general idea behind the Phase system is that you simply
create a Control root UI Scene that will serve as the controller front end, inherit from `Phase`
and override the following methods

```gdscript
func phase_init() # Find things(player entity and such) here
func phase_begin() # Enable input from after this call
func phase_end() # Lock input and clean up, without hiding/freeing things.
```

And then insert the phase into the Phases array in your note settings. Once you've done that,
phases are incredibly simple to summon with `note.phase.begin(YourPhaseType)`. When this happens
Init is called, and then the ui is instantiated, and faded in. When the fade is done, begin 
is called on the phase.

## How to use

After doing the above you have created and shown a 'phase', you should begin to set up your phases
to do the following:

- (in `phase_init`) Find the relevant nodes of interest in the current level, EG find the map node for info regarding
entities inside of it, and then find the player character that the phase will control

- (in `phase_begin`) Handle the transition to this phase with an animation to let the player realize what they
control now, and then begin processing input that will be forwarded.

- (in `phase_end`) Resign any controls on end. This could mean putting a character into an idle stance,
ending any contracts with controllable items, setting the player character's `controlled_by` to null, stuff like that.

## When to use

I've definitely worked on small games that would not benefit from this, I find it is not a good
idea for games where the UI *is* the game, rather than an interface for a 2d/3d game world.

Use this if you believe your game would benefit from having decoupled freedom in how you
model player interaction. If your project has multiple view modes such as a `PilotCharacterPhase`
for forwarding input to a character entity, a `PilotMapPhase` to shift input into your map screen,
and `PilotInventoryPhase` to shift input to an inventory screen, this state machine style approach
lets you warm up the character entity as you enter `PilotCharacterPhase`, and lock the character down
in the `phase_end` method so nothing is hard coded, and you can freely change the game's context by
simply calling `note.phase.begin` on the intended state.

extends Control
class_name Phase

## The phase system in Note mimics the one way control flow typically seen
## in Unreal Engine. Phases are what would be called the Player Controller in UE.
## Inherit from this, make a packed scene with this as the base node, and register
## it in your Note settings to make it available to swap to from anywhere.
##
## The logic behind this is that each phase should be a new interface into your game,
## whether thats "PlayerControlPhase" that looks for an entity and forwards inputs into it,
## "PauseMenuPhase" for a quick solution to pause menuing, or getting more granular with it
## and making "DrawPhase"/"PickCardPhase" phases that handle the interactions of your card game.

## VIRTUAL: Called when the phase is spawned, do things related to loading here,
## whether that an intro animation, finding relevant entities, or bootstrapping state.
func phase_init():
	pass
## VIRTUAL: Called after init, and after the fade in. Begin affecting the game
## after this is called, like forwarding inputs to the controlled character.
## Consider this the "unlock" call.
func phase_begin():
	pass
## VIRTUAL: Called as the fade out begins. Consider this the "lock" call that
## tells your phase to stop doing things with input. Apt place to put your close animations
func phase_end():
	pass

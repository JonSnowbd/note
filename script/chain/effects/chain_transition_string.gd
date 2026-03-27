extends ChainFX
class_name NoteChainEffectTransitionString

## Due to the nature of changing scenes, this is the logical end of a chain.
## Useful for scene transitions where the level loads after the player
## moves through a door frame or enters the teleporter. Changing is done
## via the [code]note.load_level[/code] functions. This chain node is never
## considered "finished", so the chain halts while loading happens.

@export_file("*.tscn", "*.scn") var scene: String
@export var transition_time: float = 0.75
@export var loading_screen: bool = true

## Virtual this is called to begin a chain node
func _start(data):
	note.level.change_to(scene, loading_screen)
func _done() -> bool:
	return true

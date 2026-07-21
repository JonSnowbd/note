extends ChainNode
class_name ChainFXTransition_PackedScene

## Due to the nature of changing scenes, this is the logical end of a chain.
## Useful for scene transitions where the level loads after the player
## moves through a door frame or enters the teleporter. Changing is done
## via the [code]note.load_level[/code] functions. This chain node is never
## considered "finished", so the chain halts while loading happens.

@export var scene: PackedScene
@export var transition_time: float = 0.75
@export var loading_screen: bool = true

func _chain_start(_instance: RunInstance):
	note.level.change_to(scene, loading_screen)
func _chain_work(instance: RunInstance, delta: float) -> Response:
	return Response.WORKING

extends ChainNode
class_name ChainFXLevelChange

## Due to the nature of changing scenes, this is the logical end of a chain if its in the level.
## Useful for scene transitions where the level loads after the player
## moves through a door frame or enters the teleporter. Changing is done
## via the [code]note.goto[/code] function. This chain node is never
## considered "finished", so the chain halts while loading happens.

@export_file("*.tscn", "*.scn") var scene_path: String
@export var scene_packed: PackedScene
@export var transition_time: float = 0.75
@export var skip_loading: bool = false
@export_file("*.tscn", "*.scn") var warm_assets: Array[String] = []
@export_file("*.tscn", "*.scn") var required_load_assets: Array[String] = []

func _chain_start(_instance: RunInstance):
	var session = (note.loading.begin_loading_screen()
	.load_prewarm_assets(warm_assets)
	.load_assets(required_load_assets))
	
	if skip_loading:
		session.skip_loading = true
	
	if scene_packed != null:
		session.level(scene_packed)
	else:
		session.level(scene_path)
func _chain_work(instance: RunInstance, delta: float) -> Response:
	return Response.DONE if note.loading.current_load_session == null else Response.WORKING

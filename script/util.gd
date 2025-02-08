extends Node
class_name NoteUtilities

var _hash_cache = {}

## Takes time as a float, and returns a speedrun style format, `MM:SS.MS`
## with appropriate padding/truncating to ensure its always
## 8 characters long. Recommended to use with a mono font.
func seconds_to_speedrun_stamp(time: float) -> String:
	var minutes: int = int(time/60.0)
	var seconds = fmod(time, 60.0)
	var ms: int = int(fmod(time, 1.0) * 1000.0)
	var ms_string: String = str(ms).substr(0,2).lpad(2,"0")
	return str(minutes).lpad(2, "0")+":"+str(int(round(seconds))).lpad(2, "0")+"."+ms_string
## Not at all accurate enough for precise requirements, but otherwise perfect for
## UI animations and other visual effects that need to be free from timescale.
func unscaled_dt() -> float:
	return 1.0/Engine.get_frames_per_second()
## Accurate, and constant. Perfect for use in any physics process that needs to be free from timescale.
func unscaled_physics_dt() -> float:
	return 1.0/Engine.physics_ticks_per_second

## If true, sets the display server to fullscreen, otherwise windowed.
func set_fullscreen(is_fullscreen: bool):
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
## Takes a number from 0.0 -> 1.0 and sets that buses volume. Converts to DB for you
func set_volume(bus_name: String, linear_volume: float):
	var vol_db = linear_to_db(linear_volume)
	if linear_volume <= 0.0 or vol_db == NAN:
		vol_db = -80.0
	var bus = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus, vol_db)
## Mutes the target bus.
func mute_volume(bus_name: String):
	set_volume(bus_name, 0.0)

func cached_hash_str(obj) -> String:
	if _hash_cache.has(obj):
		return _hash_cache[obj]
	else:
		_hash_cache[obj] = str(hash(obj))
		return _hash_cache[obj]

func vfx(prefab: PackedScene, world_position: Vector2, data = null, parent: Node = null) -> VisualEffect2D:
	var inst = prefab.instantiate() as VisualEffect2D
	var target = parent if parent != null else get_tree().current_scene
	target.add_child(inst)
	inst.global_position = world_position
	inst.reset_physics_interpolation()
	inst.effect_trigger(data)
	return inst

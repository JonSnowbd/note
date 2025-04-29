extends Node
class_name NoteUtilities

var _tween_cache: Dictionary[String,Tween] = {}

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
	return 1.0/Engine.max_fps
## Accurate, and constant. Perfect for use in any physics process that needs to be free from timescale.
func unscaled_physics_dt() -> float:
	return 1.0/Engine.physics_ticks_per_second

func smooth_move_towards_speed(from: Vector2, to: Vector2, speed: float) -> float:
	var dist = from.distance_to(to)
	return speed + (sqrt(speed*dist))

## If a tween has been started from the same id, it will be stopped and removed before returning
## this new tween. Useful for avoiding overlaps with simple tweens without handling it yourself,
## if the code path is hot enough to have potential overlaps
func clean_tween(id: String) -> Tween:
	var t = create_tween()
	if _tween_cache.has(id):
		var prev = _tween_cache[id]
		if prev.is_running():
			prev.stop()
	_tween_cache[id] = t
	return t
func clean_tween_free(id: String):
	_tween_cache.erase(id)

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

func profiler_start() -> int:
	return Time.get_ticks_msec()
## pass in the result of [code]note.util.profiler_start()[/code] for a String
## representation of the time it took.
func profiler_end(val: int) -> String:
	var time = float(Time.get_ticks_msec() - val)
	if time > 1000.0:
		return "%.2fs"%(time*1000.0)
	else:
		return "%.2fms"%time

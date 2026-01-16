extends Node

signal fullscreen_changed

enum FullscreenState {
	Unknown,
	Windowed,
	BorderlessFullscreen,
	Fullscreen,
}

var _tween_cache: Dictionary[String,Tween] = {}

## Takes time as a float, and returns a speedrun style format, `HH:MM:SS.MS`
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
## Smoothly move towards a value. Like a damped value lerp. Float version.
func smooth_toward(from: float, to: float, speed: float, delta: float) -> float:
	return lerp(from, to, 1.0 - exp(-speed * delta))
## Smoothly move towards a value. Like a damped value lerp. Vector2 version.
func smooth_toward_v2(from: Vector2, to: Vector2, speed: float, delta: float) -> Vector2:
	return from.lerp(to, 1.0 - exp(-speed * delta))
## Smoothly move towards a value. Like a damped value lerp. Vector2 version.
func smooth_toward_v3(from: Vector3, to: Vector3, speed: float, delta: float) -> Vector3:
	return from.lerp(to, 1.0 - exp(-speed * delta))
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

func get_fullscreen() -> FullscreenState:
	var current_mode = DisplayServer.window_get_mode()
	match current_mode:
		DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN:
			return FullscreenState.BorderlessFullscreen
		DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return FullscreenState.Fullscreen
		DisplayServer.WindowMode.WINDOW_MODE_WINDOWED:
			return FullscreenState.Windowed
	return FullscreenState.Unknown
## If true, sets the display server to fullscreen, otherwise windowed.
func set_screen_state(state: FullscreenState):
	var current_mode = DisplayServer.window_get_mode()
	var current_state = get_fullscreen()
	if current_state == FullscreenState.Unknown:
		return
	
	if current_state != state:
		match state:
			FullscreenState.Windowed:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			FullscreenState.BorderlessFullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			FullscreenState.Fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		fullscreen_changed.emit()

func set_fullscreen():
	set_screen_state(FullscreenState.Fullscreen)
func set_borderless_fullscreen():
	set_screen_state(FullscreenState.BorderlessFullscreen)
func set_windowed():
	set_screen_state(FullscreenState.Windowed)

## Gets the linear volume of the bus requested, from 0.0 to 2.0 (to account for users
## who wish to overclock audio volume. 0.0 to 1.0 is the normal expectation.)
func get_volume(bus_name: String) -> float:
	var bus = AudioServer.get_bus_index(bus_name)
	var vol = AudioServer.get_bus_volume_db(bus)
	return clamp(db_to_linear(vol),0.0, 2.0)

## Takes a number from 0.0 -> 1.0 and sets that buses volume. Converts to DB for you.
## You can set it beyond 1.0, or allow users to if they wish, but it is not recommended.
func set_volume(bus_name: String, linear_volume: float):
	var vol_db = linear_to_db(linear_volume)
	if linear_volume <= 0.0 or vol_db == NAN:
		vol_db = -80.0
	var bus = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus, vol_db)

## Mutes the target bus.
func mute_volume(bus_name: String):
	set_volume(bus_name, 0.0)

## Returns an integer for use in [code]profiler_end[/code].
func profiler_start() -> int:
	return Time.get_ticks_msec()

## Pass in the result of [code]note.util.profiler_start()[/code] for a String
## representation of the time it took.
func profiler_end(val: int) -> String:
	var time = float(Time.get_ticks_msec() - val)
	if time > 1000.0:
		return "%.2fs"%(time*1000.0)
	else:
		return "%.2fms"%time

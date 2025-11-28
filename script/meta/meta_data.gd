extends RefCounted

var stuck_save: String = ""
var first_launch: bool = true
var previous_master_bus_volume: float = 0.0
var previous_fullscreen_mode: int = 0


func _init() -> void:
	if FileAccess.file_exists("user://__note.json"):
		var fi = FileAccess.open("user://__note.json", FileAccess.READ)
		if fi == null:
			push_error("Note Metadata failed to load data due to a load error")
			return
		var json = JSON.parse_string(fi.get_as_text())
		fi.close()
		stuck_save = json["stuck_save"]
		previous_master_bus_volume = json["previous_master_bus_volume"]
		previous_fullscreen_mode = json["previous_fullscreen_mode"]
		first_launch = json["first_launch"]
func persist(_nt) -> void:
	previous_fullscreen_mode = _nt.util.get_fullscreen()
	previous_master_bus_volume = _nt.util.get_volume("Master")
	var fi = FileAccess.open("user://__note.json", FileAccess.WRITE)
	fi.store_string(JSON.stringify({
		"stuck_save" = stuck_save,
		"previous_master_bus_volume" =  previous_master_bus_volume,
		"previous_fullscreen_mode" = previous_fullscreen_mode,
		"first_launch" = false,
	}))
	fi.close()

func restore_soft_settings(_nt) -> void:
	_nt.util.set_fullscreen(previous_fullscreen_mode)
	_nt.util.set_volume("Master", previous_master_bus_volume)

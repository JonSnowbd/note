extends CanvasLayer

@export var transition_time: float = 0.33
## If true, _process and _input will be killed on phases during the leave
## animation.
@export var kill_processes_on_end: bool = false

var current_phase: Phase = null
var lookup: Dictionary = {}
var _awaiting_init: bool = false
var _is_current_phase_instant: bool = false

var loads_remaining: PackedStringArray = []

func _register(path: String):
	var packed_scene = note.loading_screen.force_fetch(path)
	var instance = packed_scene.instantiate()
	lookup[instance.name] = packed_scene
	lookup[packed_scene] = packed_scene
	lookup[instance.get_script()] = packed_scene
	lookup[path] = packed_scene
	instance.queue_free()
	if note.settings.note_info_prints:
		note.info("Registered new phase -> [b]"+instance.name+"[/b]", "PHSMNGR")

func _is_all_loaded() -> bool:
	return loads_remaining.is_empty()


func _ready() -> void:
	if note.settings.test_mode:
		return
	note.loading_screen.loading_shadow_file_finished.connect(func(path):
		if loads_remaining.is_empty(): return
		if loads_remaining.has(path):
			_register(path)
			loads_remaining.erase(path)
	)
	for phase in note.settings.phases:
		loads_remaining.append(phase)
		note.loading_screen.shadow_load(phase)

## Just incase the user tries to load a phase REALLY early,
## just force the whole load.
func _force_loads():
	if !_is_all_loaded():
		pass
func begin(identity) -> Variant:
	_force_loads()
	end()
	if lookup.has(identity):
		var packed: PackedScene = lookup[identity]
		var new_phase: Phase = packed.instantiate()
		current_phase = new_phase
		if note.settings.note_info_prints:
			note.info("Beginning phase: [b]"+new_phase.name+"[/b]", "PHSMNGR")
		add_child(new_phase)
		new_phase.modulate.a = 0.0
		_awaiting_init = true
		_is_current_phase_instant = false
		var t = create_tween()
		t.tween_property(new_phase, "modulate:a", 1.0, transition_time)
		t.tween_callback(new_phase.phase_begin)
		
		return new_phase
	else:
		note.error("note.phase.begin called with '%s' which doesnt exist. Is it in your note settings?" % str(identity))
	return null

## Ends the current phase with no animation if it exists, and then, with
## no animation, instantiates and begins the new phase.
func begin_instant(identity) -> Variant:
	_force_loads()
	end_instant()
	if lookup.has(identity):
		var packed: PackedScene = lookup[identity]
		var new_phase: Phase = packed.instantiate()
		current_phase = new_phase
		if note.settings.note_info_prints:
			note.info("Beginning phase: [b]"+new_phase.name+"[/b]", "PHSMNGR")
		add_child(new_phase)
		_awaiting_init = true
		_is_current_phase_instant = true
		return new_phase
	return null
func end():
	if current_phase != null:
		current_phase.phase_end()
		if kill_processes_on_end:
			current_phase.set_physics_process(false)
			current_phase.set_process(false)
			current_phase.set_process_input(false)
		
		var t = create_tween()
		t.tween_property(current_phase, "modulate", Color(1.0, 1.0, 1.0, 0.0), transition_time)
		t.tween_callback(current_phase.queue_free)
		
		current_phase = null
func end_instant():
	if current_phase != null:
		current_phase.phase_end()
		current_phase.queue_free()
		current_phase = null

func _process(delta: float) -> void:
	if _awaiting_init and current_phase != null:
		current_phase.phase_init()
		if _is_current_phase_instant:
			current_phase.phase_begin()
		_awaiting_init = false

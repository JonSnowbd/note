extends CanvasLayer

@export var transition_time: float = 0.33
## If true, _process and _input will be killed on phases during the leave
## animation.
@export var kill_processes_on_end: bool = false

var current_phase: Phase = null

var lookup: Dictionary = {}

@onready var _nt = get_tree().root.get_node("note")

var loads_remaining: PackedStringArray = []

func _register(path: String):
	var packed_scene = _nt.loading_screen.force_fetch(path)
	var instance = packed_scene.instantiate()
	lookup[instance.name] = packed_scene
	lookup[packed_scene] = packed_scene
	lookup[instance.get_script()] = packed_scene
	lookup[path] = packed_scene
	instance.queue_free()
	_nt.info("Registered new phase -> [b]"+instance.name+"[/b]", "PHSMNGR")

func _is_all_loaded() -> bool:
	return loads_remaining.is_empty()


func _ready() -> void:
	_nt.loading_screen.loading_shadow_file_finished.connect(func(path):
		if loads_remaining.is_empty(): return
		if loads_remaining.has(path):
			_register(path)
			loads_remaining.erase(path)
	)
	for phase in _nt.settings.phases:
		loads_remaining.append(phase)
		_nt.loading_screen.shadow_load(phase)

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
		_nt.info("Beginning phase: [b]"+new_phase.name+"[/b]", "PHSMNGR")
		add_child(new_phase)
		new_phase.modulate.a = 0.0
		new_phase.phase_init()
		
		var t = create_tween()
		t.tween_property(new_phase, "modulate:a", 1.0, transition_time)
		t.tween_callback(new_phase.phase_begin)
		
		return new_phase
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
		_nt.info("Beginning phase: [b]"+new_phase.name+"[/b]", "PHSMNGR")
		add_child(new_phase)
		new_phase.phase_init()
		new_phase.phase_begin()
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

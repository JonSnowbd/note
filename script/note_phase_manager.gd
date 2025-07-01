extends CanvasLayer
class_name NotePhaseManager

@export var transition_time: float = 0.2
@export var phase_root: Control

var previous_phase_identity = null
var current_phase_identity = null
var current_phase: NotePhaseLayer = null
var data: Dictionary[Variant, NotePhaseLayer] = {}
var active_tweens: Dictionary[Variant, Tween] = {}

func _clear_active_tweens(identity):
	if active_tweens.has(identity):
		var old_t: Tween = active_tweens[identity]
		if old_t.is_running():
			old_t.stop()
		active_tweens.erase(identity)

func is_phase_initialized(identity) -> bool:
	return data.has(identity)
func get_phase(identity) -> Variant:
	if data.has(identity):
		return data[identity]
	return null
func is_phase(identity) -> bool:
	if !data.has(identity):
		return false
	return data[identity] == current_phase
func register_phase(identity, package: PackedScene):
	var new_phase: NotePhaseLayer = package.instantiate()
	new_phase.phase_identity = identity
	phase_root.add_child(new_phase)
	phase_root.set_meta("default_process_mode", phase_root.process_mode)
	data[identity] = new_phase
	new_phase.phase_init()
	_shelf_phase(new_phase.phase_identity)
func switch_phase(identity, transition_data=null):
	clear_phase()
	current_phase_identity = identity
	if identity == null:
		return
	var next_phase: NotePhaseLayer = data[identity]
	next_phase.process_mode = next_phase.get_meta("default_process_mode", PROCESS_MODE_ALWAYS)
	next_phase.show()
	next_phase.phase_begin(transition_data)
	next_phase.modulate = Color(1.0, 1.0, 1.0, 0.0)
	current_phase = next_phase
	_clear_active_tweens(next_phase.phase_identity)
	var t = create_tween()
	t.tween_property(next_phase, "modulate", Color(1.0, 1.0, 1.0, 1.0), transition_time)
	active_tweens[next_phase.phase_identity] = t
func clear_phase():
	previous_phase_identity = current_phase_identity
	current_phase_identity = null
	if current_phase != null:
		_clear_active_tweens(current_phase.phase_identity)
		current_phase.phase_end()
		current_phase.process_mode = Node.PROCESS_MODE_DISABLED
		current_phase.modulate = Color(1.0, 1.0, 1.0, 1.0)
		var t = create_tween()
		t.tween_property(current_phase, "modulate", Color(1.0, 1.0, 1.0, 0.0), transition_time)
		t.tween_callback(_shelf_phase.bind(current_phase.phase_identity))
		active_tweens[current_phase.phase_identity] = t
func _shelf_phase(identity):
	var phase: NotePhaseLayer = data[identity]
	phase.hide()
	phase.process_mode = Node.PROCESS_MODE_DISABLED

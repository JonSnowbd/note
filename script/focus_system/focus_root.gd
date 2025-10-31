extends Control

signal on_begin(new_target: Control)
signal changed_control(new_control: Control)
signal on_end()

## Taps longer than this are auto-sent as a long press.
@export var long_press_duration: float = 0.4
## Taps need to be shorter than this to count as a press
@export var tap_requirement: float = 0.2
## If true processing happens in the physics thread
@export var physics_mode: bool = false

@export_group("Design")
@export var regular_box: StyleBox
@export_group("Audio")
@export var sfx_pitch_variance: float = 0.05
@export var sfx_move: AudioStreamPlayer
@export var sfx_activate: AudioStreamPlayer
@export var sfx_charge: AudioStreamPlayer
@export var sfx_press: AudioStreamPlayer
@export var sfx_long_press: AudioStreamPlayer
@export var sfx_up: AudioStreamPlayer
@export var sfx_down: AudioStreamPlayer

var active: bool = false
var target: Control = null
## If >=0, note will handle everything for you, you only need to wait for
## the focus to be over before resuming your own input handling.
## Set to -1 if you want to handle it all manually.
var automatic_gamepad_id: int = -1

var _impulse_trip: bool = false
var _loaded_effects: Array[FocusEffect] = []
var _stacked_effects: Array[FocusEffect] = []
var _scroll: ScrollContainer = null
var _overflow: Vector2 = Vector2.ZERO

## Confirm, Cancel, Special1, Special2
var _times: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _states: Array[bool] = [false, false, false, false]

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	if !physics_mode:
		_cycle(delta)
func _physics_process(delta: float) -> void:
	if physics_mode:
		_cycle(delta)
func _draw() -> void:
	draw_style_box(regular_box, Rect2(Vector2.ZERO, size))
	var local = Rect2(target.global_position-global_position, target.size)
	for fx: FocusEffect in _loaded_effects:
		fx.focus_draw(self)
	for fx: FocusEffect in _stacked_effects:
		fx.focus_draw(self)
func _unhandled_input(event: InputEvent) -> void:
	if automatic_gamepad_id < 0:
		return
	if event is InputEventJoypadButton:
		if event.device != automatic_gamepad_id: return
		if event.button_index == JOY_BUTTON_DPAD_UP and event.pressed:
			send_up()
			accept_event()
			return
		if event.button_index == JOY_BUTTON_DPAD_DOWN and event.pressed:
			send_down()
			accept_event()
			return
		if event.button_index == JOY_BUTTON_DPAD_LEFT and event.pressed:
			send_left()
			accept_event()
			return
		if event.button_index == JOY_BUTTON_DPAD_RIGHT and event.pressed:
			send_right()
			accept_event()
			return
		if event.button_index == JOY_BUTTON_A:
			send_confirm(event.is_pressed())
			accept_event()
			return
		if event.button_index == JOY_BUTTON_B:
			send_cancel(event.is_pressed())
			accept_event()
			return
		if event.button_index == JOY_BUTTON_X:
			send_special1(event.is_pressed())
			accept_event()
			return
		if event.button_index == JOY_BUTTON_Y:
			send_special2(event.is_pressed())
			accept_event()
			return

func _send_dir(dir: Vector2):
	var next = _get_next_item(target, dir)
	if next == null:
		var butt_consumed: bool = false
		for fx in _stacked_effects:
			if fx.focus_butted(dir):
				butt_consumed = true
				break
		if !butt_consumed:
			for fx in _loaded_effects:
				if fx.focus_butted(dir):
					butt_consumed = true
					break
	else:
		_change(next)
func send_up():
	var dir = Vector2(0.0,-1.0)
	_send_dir(dir)
func send_down():
	var dir = Vector2(0.0,1.0)
	_send_dir(dir)
func send_left():
	var dir = Vector2(-1.0,0.0)
	_send_dir(dir)
func send_right():
	var dir = Vector2(1.0,0.0)
	_send_dir(dir)
func send_impulse(stick: Vector2):
	var l = stick.length()
	if l > 0.5 and !_impulse_trip:
		_send_dir(stick)
		_impulse_trip = true
	
	if l < 0.4:
		_impulse_trip = false

func get_local_rect(target_node: Control) -> Rect2:
	return Rect2(target_node.global_position-global_position, target_node.size)

func _send_btn(down: bool, state_id: int, send_fn: String, pitch_shift: float = 0.0):
	var long_press = _has_long_press()
	if down:
		if !long_press:
			var button_consumed: bool = false
			# Check stacked effects first.
			# TODO: Reverse the order, so newer stacked items win first.
			for fx in _stacked_effects:
				if fx.call(send_fn, true, false):
					button_consumed = true
					break
			# If it wasnt consumed, check with the other current effects first.
			if !button_consumed:
				for fx in _loaded_effects:
					if fx.call(send_fn, true, false):
						button_consumed = true
						break
		
		sfx_down.pitch_scale = randf_range(1.0-sfx_pitch_variance, 1.0+sfx_pitch_variance)+pitch_shift
		sfx_down.play()
	else:
		var button_consumed: bool = false
		for fx in _stacked_effects:
			if fx.call(send_fn, false, false):
				button_consumed = true
				break
		sfx_up.pitch_scale = randf_range(1.0-sfx_pitch_variance, 1.0+sfx_pitch_variance)+pitch_shift
		sfx_up.play()
	_states[state_id] = down
func send_confirm(down: bool):
	_send_btn(down, 0, "focus_confirm")
func send_cancel(down: bool):
	_send_btn(down, 1, "focus_cancel", -0.08)
func send_special1(down: bool):
	_send_btn(down, 2, "focus_special1", 0.08)
func send_special2(down: bool):
	_send_btn(down, 3, "focus_special2", 0.12)

func activate(start: Control):
	show()
	_overflow = Vector2.ZERO
	_change(start)
	active = true
	on_begin.emit(target)
func deactivate():
	on_end.emit()
	hide()

func send_scroll(stick: Vector2, delta: float, speed: float = 450.0):
	if _scroll != null:
		if stick.length() > 0.2:
			_overflow += stick * delta * speed

## Check this first when doing input, and defer to the result.
## If true, disregard your usual inputs, and send the focus API calls,
## if false, prefer your games usual inputs, and ignore the focus API.
func is_consuming_input() -> bool:
	return active and target != null

func _acknowledge(control: Control):
	for c in control.get_children():
		if c is FocusEffect:
			c.focus_acknowledge()
func _change(new_target: Control):
	var just_began: bool = target == null
	if new_target == null: deactivate()
	_scroll = null
	for fx in _loaded_effects:
		fx.focus_exit()
	_loaded_effects.clear()
	for c in new_target.get_children():
		if c is FocusEffect:
			c.manager = self
			if _stacked_effects.has(c): continue
			_loaded_effects.append(c as FocusEffect)
			c.focus_enter()
	
	target = new_target
	var parent = target.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			_scroll = parent as ScrollContainer
		if parent.has_meta(FocusEffect.MetaTag):
			_acknowledge(parent)
		parent = parent.get_parent()
	
	if _scroll != null:
		await get_tree().process_frame
		_scroll.ensure_control_visible(target)
	
	if !just_began:
		sfx_move.pitch_scale = randf_range(1.0-sfx_pitch_variance, 1.0+sfx_pitch_variance)
		sfx_move.play()
	changed_control.emit(target)
func _has_long_press() -> bool:
	for fx in _loaded_effects:
		if fx.has_long_press:
			return true
	for fx in _stacked_effects:
		if fx.has_long_press:
			return true
	return false
func _cycle(delta: float) -> void:
	if !active:
		return
	if target == null or !is_instance_valid(target) or target.is_queued_for_deletion() or !target.visible:
		deactivate()
		return
	_move_to_target(3500.0*delta, 1000.0*delta)
	
	if automatic_gamepad_id >= 0:
		var ls = Vector2.ZERO
		ls.x = Input.get_joy_axis(automatic_gamepad_id, JOY_AXIS_LEFT_X)
		ls.y = Input.get_joy_axis(automatic_gamepad_id, JOY_AXIS_LEFT_Y)
		var rs = Vector2.ZERO
		rs.x = Input.get_joy_axis(automatic_gamepad_id, JOY_AXIS_RIGHT_X)
		rs.y = Input.get_joy_axis(automatic_gamepad_id, JOY_AXIS_RIGHT_Y)
		send_impulse(ls)
		send_scroll(rs, delta)
	
	var y_add: int = floori(abs(_overflow.y)) * int(sign(_overflow.y))
	var x_add: int = floori(abs(_overflow.x)) * int(sign(_overflow.x))
	_overflow.y -= y_add
	_overflow.x -= x_add
	if _scroll != null:
		_scroll.scroll_vertical += y_add
		_scroll.scroll_horizontal += x_add
	
	for i in range(len(_times)):
		if _states[i]:
			_times[i] += delta
		else:
			_times[i] = 0.0
	
	queue_redraw()

func _move_to_target(position_speed: float,size_speed: float):
	var corrected = target.get_global_rect()
	
	position = position.move_toward(corrected.position, position_speed)
	size = size.move_toward(corrected.size, size_speed)

func _get_next_item(source: Control, impulse: Vector2) -> Control:
	var path: NodePath = ""
	if abs(impulse.x) > 0.5 and abs(impulse.y) < 0.33:
		path = source.focus_neighbor_right if impulse.x > 0.0 else source.focus_neighbor_left
	if abs(impulse.x) < 0.33 and abs(impulse.y) > 0.5:
		path = source.focus_neighbor_bottom if impulse.y > 0.0 else source.focus_neighbor_top
	if path.is_empty():
		return null
	else:
		return source.get_node(path)

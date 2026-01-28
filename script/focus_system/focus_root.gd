extends Control

signal on_begin(new_target: Control)
signal changed_control(new_control: Control)
signal on_end()
signal lost_focus

## Taps longer than this are auto-sent as a long press.
@export var long_press_duration: float = 0.4
## Taps need to be shorter than this to count as a press
@export var tap_requirement: float = 0.2
## If true processing happens in the physics thread
@export var physics_mode: bool = false

@export_group("Design")
@export var regular_box: StyleBox
@export_group("Audio")
@export var sfx_pitch_variance: float = 0.035
@export var sfx_move: AudioStreamPlayer
@export var sfx_activate: AudioStreamPlayer
@export var sfx_charge: AudioStreamPlayer
@export var sfx_press: AudioStreamPlayer
@export var sfx_long_press: AudioStreamPlayer
@export var sfx_up: AudioStreamPlayer
@export var sfx_down: AudioStreamPlayer
@export var sfx_fail: AudioStreamPlayer

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

var _current_t: Transform2D
var time_since_start: float = 0.0

## If true, any calls to begin are ignored.
var locked: bool = false

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	if !physics_mode:
		_cycle(delta)
func _physics_process(delta: float) -> void:
	if physics_mode:
		_cycle(delta)
func _draw() -> void:
	global_position = Vector2.ZERO
	draw_set_transform_matrix(_current_t)
	draw_style_box(regular_box, Rect2(Vector2.ZERO, size*_current_t.get_scale()))
	for fx: FocusEffect in _loaded_effects:
		fx.focus_draw(self)
	for fx: FocusEffect in _stacked_effects:
		fx.focus_draw(self)
func _input(event: InputEvent) -> void:
	if locked: return
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
	if locked or !is_active(): return
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

func _send_btn(down: bool, state_id: int, send_fn: String, pitch_shift: float = 0.0):
	var long_press = _has_long_press()
	if down:
		var button_consumed: bool = false
		if !long_press:
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
		if button_consumed:
			sfx_down.pitch_scale = randf_range(1.0-sfx_pitch_variance, 1.0+sfx_pitch_variance)+pitch_shift
			sfx_down.play()
		else:
			sfx_fail.play()
	else:
		var button_consumed: bool = false
		for fx in _stacked_effects:
			if fx.call(send_fn, false, false):
				button_consumed = true
				break
		if !button_consumed:
			for fx in _loaded_effects:
				if fx.call(send_fn, false, false):
					button_consumed = true
					break
		if button_consumed:
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

func activate(start: Control, fade_in_duration: float = 0.0, fade_in_delay: float = 0.0):
	if locked or is_active(): return
	reset()
	show()
	if fade_in_duration > 0.0:
		var t = create_tween()
		modulate.a = 0.0
		if fade_in_delay > 0.0:
			t.tween_interval(fade_in_delay)
		t.tween_property(self, "modulate:a", 1.0, fade_in_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	else:
		modulate.a = 1.0
	_change(start)
	active = true
	on_begin.emit(target)
func deactivate(is_loss: bool = false):
	reset()
	active = false
	_loaded_effects.clear()
	on_end.emit()
	target = null
	hide()
	if is_loss:
		lost_focus.emit()
## Resets special state like the stack and scrolling overflow.
func reset():
	_stacked_effects.clear()
	_overflow = Vector2.ZERO
	time_since_start = 0.0

func get_target_transform(of: Control) -> Transform2D:
	var t = of.get_screen_transform()
	return t

func send_scroll(stick: Vector2, delta: float, speed: float = 450.0):
	if _scroll != null:
		if stick.length() > 0.2:
			_overflow += stick * delta * speed

## Check this first when doing input, and defer to the result.
## If true, disregard your usual inputs, and send the focus API calls,
## if false, prefer your games usual inputs, and ignore the focus API.
func is_consuming_input() -> bool:
	return active and target != null

func is_active() -> bool:
	return active

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
	#_move_to_target(0.2)
	var parent = target.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			_scroll = parent as ScrollContainer
		if parent.has_meta(FocusEffect.MetaTag):
			_acknowledge(parent)
		parent = parent.get_parent()
	
	if _scroll != null:
		await get_tree().process_frame
		if _scroll != null:
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
	if !is_active():
		return
	time_since_start += delta
	if target == null or !is_instance_valid(target) or target.is_queued_for_deletion():
		deactivate()
		lost_focus.emit()
		return

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
	
	if target.is_inside_tree():
		if time_since_start < 0.2:
			_current_t = get_target_transform(target)
			size = target.size
		else:
			var target_dest = get_target_transform(target)
			size = note.util.smooth_toward_v2(size, target.size, 17.0, delta)
			_current_t = note.util.smooth_toward_tform2(_current_t, target_dest, 14.0, delta)
	
	queue_redraw()

## Going from source, and looking in the stick direction "impulse" find
## the most likely next item its requesting. 
func _get_next_item(source: Control, impulse: Vector2) -> Control:
	var path: NodePath = ""
	if abs(impulse.x) > 0.5 and abs(impulse.y) < 0.33:
		path = source.focus_neighbor_right if impulse.x > 0.0 else source.focus_neighbor_left
	elif abs(impulse.x) < 0.33 and abs(impulse.y) > 0.5:
		path = source.focus_neighbor_bottom if impulse.y > 0.0 else source.focus_neighbor_top
	if path.is_empty():
		return null
	else:
		var node = source.get_node(path)
		if node is Control:
			if node.has_meta(FocusDynamicEntrance.MetaTag):
				var meta: FocusDynamicEntrance = node.get_meta(FocusDynamicEntrance.MetaTag)
				var to_local = node.make_canvas_position_local(source.global_position)
				return meta.get_new_target(to_local, impulse)
		return node

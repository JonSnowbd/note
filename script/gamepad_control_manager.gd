extends Node2D
class_name NoteGamepadControlManager

@export_category("Settings")
@export var auto_enable: bool
@export var highlight_stylebox: StyleBox

@export_category("Setup")
@export var first_node: Control
@export var change_node_sound: AudioStreamPlayer
@export var primary_sound: AudioStreamPlayer
@export var secondary_sound: AudioStreamPlayer

@export_category("Inputs")
@export var up_action: Array[String] = []
@export var down_action: Array[String] = []
@export var left_action: Array[String] = []
@export var right_action: Array[String] = []
@export var confirm_action: Array[String] = []
@export var cancel_action: Array[String] = []
@export var next_window_action: Array[String] = []
@export var prev_window_action: Array[String] = []

var focused_control: Control = null
var box_size: Vector2 = Vector2.ZERO
var active: bool = false

var stick_trip_id: int = -1
var stick_trip: bool = false

var current_handlers: Array[NoteGamepadControlHandler]
var current_effects: Array[NoteGamepadControlEffect]

func _ready() -> void:
	note.control_mode_changed.connect(func():
		if !note.is_gamepad:
			stop()
			hide()
	)

func move_into(new_control: Control):
	if new_control == focused_control:
		return
	if new_control == null:
		stop()
		return
	focused_control = new_control
	# Leave effects and handlers
	for handler in current_handlers:
		handler.handler_left()
	for fx in current_effects:
		fx.effect_end()
	
	current_handlers.clear()
	current_effects.clear()
	# Fetch handler
	if new_control.has_meta(NoteGamepadControlHandler.MetaTag_ID):
		var objs = new_control.get_meta(NoteGamepadControlHandler.MetaTag_ID)
		for obj in objs:
			if obj is NoteGamepadControlHandler:
				current_handlers.append(obj)
	# Fetch effects
	if new_control.has_meta(NoteGamepadControlEffect.MetaTag_ID):
		var objs = new_control.get_meta(NoteGamepadControlEffect.MetaTag_ID)
		for obj in objs:
			if obj is NoteGamepadControlEffect:
				current_effects.append(obj)
	
	# enter new things
	for handle in current_handlers:
		handle.handler_entered()
	for effect in current_effects:
		effect.effect_start()
	
func start(target: Control=null):
	if target == null:
		target = first_node
	active = true
	note.popup.send("Activating the gamepad mode for menu")
	move_into(target)
	show()
func stop():
	active = false
	stick_trip = false
	stick_trip_id = -1
	note.popup.send("Done")
	hide()

func _input(event: InputEvent) -> void:
	if active:
		if event is InputEventJoypadMotion:
			if stick_trip:
				if stick_trip_id == event.axis:
					if is_zero_approx(event.axis_value):
						stick_trip = false
						stick_trip_id = -1
					else:
						return
				else:
					return
		
		for handler in current_handlers:
			if handler.handler_input(self, event):
				return
		for up in up_action:
			if event.is_action_pressed(up): 
				var node = focused_control.get_node_or_null(focused_control.focus_neighbor_top)
				if node != null:
					move_into(node)
				if event is InputEventJoypadMotion:
					stick_trip = true
					stick_trip_id = event.axis
		for down in down_action:
			if event.is_action_pressed(down):
				var node = focused_control.get_node_or_null(focused_control.focus_neighbor_bottom)
				if node != null:
					move_into(node)
				if event is InputEventJoypadMotion:
					stick_trip = true
					stick_trip_id = event.axis
		for left in left_action:
			if event.is_action_pressed(left):
				var node = focused_control.get_node_or_null(focused_control.focus_neighbor_left)
				if node != null:
					move_into(node)
				if event is InputEventJoypadMotion:
					stick_trip = true
					stick_trip_id = event.axis
		for right in right_action:
			if event.is_action_pressed(right):
				var node = focused_control.get_node_or_null(focused_control.focus_neighbor_right)
				if node != null:
					move_into(node)
				if event is InputEventJoypadMotion:
					stick_trip = true
					stick_trip_id = event.axis
func _process(delta: float) -> void:
	if active:
		if focused_control == null or !focused_control.visible:
			stop()
			queue_redraw()
			return
		
		for effect in current_effects:
			effect.effect_process(delta)
		
		var cam: Camera2D = focused_control.get_viewport().get_camera_2d()
		var trans = focused_control.get_global_transform_with_canvas()
		
		var target_pos = trans.get_origin()
		var target_rot = trans.get_rotation()
		global_position = global_position.move_toward(target_pos, 2500.0*delta)
		rotation = move_toward(rotation, target_rot, 3*PI*delta)
		box_size = box_size.move_toward(focused_control.size, 1000.0 * delta)
		queue_redraw()
	


func _draw() -> void:
	if highlight_stylebox != null and box_size != Vector2.ZERO:
		draw_style_box(highlight_stylebox, Rect2(Vector2.ZERO, box_size))
	if focused_control != null:
		for effect in current_effects:
			effect.effect_draw(self, focused_control)

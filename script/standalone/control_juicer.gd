extends Node
class_name ControlJuicer

static func add_to(ctrl: Control):
	var juicer = ControlJuicer.new()
	ctrl.add_child(juicer)

@export var controls: Control
@export var return_speed: float = 6.0


@export_group("On Hover", "on_hover_")
@export var on_hover_sound: AudioStreamPlayer
@export var on_hover_position_hit_x: Vector2 = Vector2(-5.0, 5.0)
@export var on_hover_position_hit_y: Vector2 = Vector2(-5.0, 5.0)
@export var on_hover_scale_hit_x: Vector2 = Vector2(1.2, 1.5)
@export var on_hover_scale_hit_y: Vector2 = Vector2(0.7, 0.9)
@export var on_hover_rotation_hit: Vector2 = Vector2(-0.2,0.2)
@export_group("On UnHover", "on_unhover_")
@export var on_unhover_sound: AudioStreamPlayer
@export var on_unhover_position_hit_x: Vector2 = Vector2(-1.0, 1.0)
@export var on_unhover_position_hit_y: Vector2 = Vector2(-1.0, 5.0)
@export var on_unhover_scale_hit_x: Vector2 = Vector2(0.8, 0.9)
@export var on_unhover_scale_hit_y: Vector2 = Vector2(1.0, 1.0)
@export var on_unhover_rotation_hit: Vector2 = Vector2(-0.03,0.03)
@export_group("On Click", "on_click_")
@export var on_click_sound: AudioStreamPlayer
@export var on_click_position_hit_x: Vector2 = Vector2(-2.0, 2.0)
@export var on_click_position_hit_y: Vector2 = Vector2(-2.0, 2.0)
@export var on_click_scale_hit_x: Vector2 = Vector2(1.0, 1.0)
@export var on_click_scale_hit_y: Vector2 = Vector2(0.8, 1.0)
@export var on_click_rotation_hit: Vector2 = Vector2(-0.1,0.1)

func hover_changed(old: Control, new: Control):
	if new == controls:
		if on_hover_sound != null: on_hover_sound.play()
		controls.offset_transform_position.x = randf_range(on_hover_position_hit_x.x, on_hover_position_hit_x.y)
		controls.offset_transform_position.y = randf_range(on_hover_position_hit_y.x, on_hover_position_hit_y.y)
		controls.offset_transform_scale.x = randf_range(on_hover_scale_hit_x.x, on_hover_scale_hit_x.y)
		controls.offset_transform_scale.y = randf_range(on_hover_scale_hit_y.x, on_hover_scale_hit_y.y)

		controls.offset_transform_rotation = randf_range(on_hover_rotation_hit.x, on_hover_rotation_hit.y)
	elif old == controls:
		if on_unhover_sound != null: on_unhover_sound.play()
		controls.offset_transform_position.x = randf_range(on_unhover_position_hit_x.x, on_unhover_position_hit_x.y)
		controls.offset_transform_position.y = randf_range(on_unhover_position_hit_y.x, on_unhover_position_hit_y.y)
		controls.offset_transform_scale.x = randf_range(on_unhover_scale_hit_x.x, on_unhover_scale_hit_x.y)
		controls.offset_transform_scale.y = randf_range(on_unhover_scale_hit_y.x, on_unhover_scale_hit_y.y)

		controls.offset_transform_rotation = randf_range(on_unhover_rotation_hit.x, on_unhover_rotation_hit.y)
func reset_node():
	controls.offset_transform_position = Vector2.ZERO
	controls.offset_transform_position_ratio = Vector2.ZERO
	controls.offset_transform_scale = Vector2.ONE
	controls.offset_transform_rotation = 0.0


func _enter_tree() -> void:
	if controls == null: controls = get_parent() as Control
	controls.offset_transform_enabled = true
	controls.offset_transform_visual_only = true
	note.controls.hovered_node_changed.connect(hover_changed)
func _exit_tree() -> void:
	note.controls.hovered_node_changed.disconnect(hover_changed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if note.controls.hovered_node == controls:
			if event.button_index == MOUSE_BUTTON_LEFT:
				controls.offset_transform_position.x = randf_range(on_click_position_hit_x.x, on_click_position_hit_x.y)
				controls.offset_transform_position.y = randf_range(on_click_position_hit_y.x, on_click_position_hit_y.y)
				controls.offset_transform_scale.x = randf_range(on_click_scale_hit_x.x, on_click_scale_hit_x.y)
				controls.offset_transform_scale.y = randf_range(on_click_scale_hit_y.x, on_click_scale_hit_y.y)
				controls.offset_transform_rotation = randf_range(on_click_rotation_hit.x, on_click_rotation_hit.y)


func _process(delta: float) -> void:
	controls.offset_transform_position = NoteUtil.smooth_toward_v2(controls.offset_transform_position, Vector2.ZERO, return_speed, delta)
	controls.offset_transform_scale = NoteUtil.smooth_toward_v2(controls.offset_transform_scale, Vector2.ONE, return_speed, delta)
	controls.offset_transform_rotation= NoteUtil.smooth_toward(controls.offset_transform_rotation, 0.0, return_speed, delta)

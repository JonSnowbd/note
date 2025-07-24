@tool
extends Node2D
class_name CuteAttachment2D

@export_group("References")
@export var work_in_physics_process: bool = true
## Optional, but more performant if assigned. Hands are created
## as siblings of the cute sprite for proper z layer.
@export var target_sprite: CuteSprite2D
## The raised object, preferably a child of the attachment.
@export var secondary_object: Node2D
@export var secondary_object_base_rotation: float = 0.0
## If true, on ready this attachment will be invisible.
@export var start_stowed: bool = false

@export_group("Inheritance")
@export var inherit_rotation: float = 1.0
@export var inherit_position: float = 1.0
@export var inherit_raise: float = 1.0

@export_group("General Pose")
@export var facing_offset: float
@export var distance: float = 6.0
@export var raise: float = 4.75

var _last_valid_look: Vector2 = Vector2.RIGHT

func _enter_tree() -> void:
	if !Engine.is_editor_hint() and start_stowed:
		stow(0.0)
func _work(delta: float):
	if !visible or target_sprite == null:
		return
	
	var lookat = target_sprite.look_at_position
	if lookat.length() < 0.1:
		lookat = _last_valid_look
	var forward = target_sprite.look_at_position.normalized().angle()+facing_offset
	var offset = target_sprite.framedata.positional_offset
	
	var raise = raise+(target_sprite.framedata.height*inherit_raise)
	var angle = forward+facing_offset
	position = Vector2.RIGHT.rotated(angle)*(distance)
	
	if secondary_object != null:
		secondary_object.position = Vector2(0, -raise)
		secondary_object.rotation = secondary_object_base_rotation+angle
	_last_valid_look = lookat
func _process(delta: float) -> void:
	if !work_in_physics_process:
		_work(delta)
func _physics_process(delta: float) -> void:
	if work_in_physics_process:
		_work(delta)

func reset_pose():
	facing_offset = 0.0
	distance = 6.0
	raise = 4.75
## Will create a tween, and subtween it if provided a root tween.
## The attachment will then fade away and fall down
func stow(duration: float = 0.2, stem_tween: Tween = null) -> Tween:
	if duration <= 0.0:
		modulate.a = 0.0
		distance = 0.25
		return null
	var t: Tween = create_tween()
	if stem_tween != null:
		stem_tween.tween_subtween(t)
	t.set_parallel(true)
	t.tween_property(self, "modulate:a", 0.0, duration)
	t.tween_property(self, "distance", 0.25, duration)
	return t
func unstow(duration: float = 0.2, stem_tween: Tween = null) -> Tween:
	if duration <= 0.0:
		modulate.a = 1.0
		distance = 6.0
		return null
	var t: Tween = create_tween()
	if stem_tween != null:
		stem_tween.tween_subtween(t)
	t.set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, duration)
	t.tween_property(self, "distance", 5.0, duration)
	return t

func tween_to(n_angle: float, n_distance: float, n_raise: float, duration: float, stem_tween: Tween = null) -> Tween:
	var t = create_tween()
	
	
	t.set_parallel(true)
	t.tween_property(self, "facing_offset", n_angle, duration)
	t.tween_property(self, "distance", n_distance, duration)
	t.tween_property(self, "raise",  n_raise, duration)
	
	if stem_tween != null:
		stem_tween.tween_subtween(t)
		
	return t
func get_real_facing() -> float:
	if target_sprite == null: return 0.0
	return target_sprite.look_at_position.normalized().angle()+facing_offset

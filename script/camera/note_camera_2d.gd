extends Camera2D
class_name NoteCamera2D

## A 2d camera with a system for effects, and in-world affectors that
## snap it to view areas.

class Effect extends RefCounted:
	enum Response {
		DONE,
		OK,
		ERR
	}
	func apply(delta: float, target: NoteCamera2D) -> Response:
		return Response.DONE

class NoteCameraEffectShake extends Effect:
	var life = 2.0
	var shake_strength = 0.0
	func _init(duration: float, power: float):
		life = duration
		shake_strength = power
	func apply(delta: float, target: NoteCamera2D) -> Response:
		life -= delta
		if life <= 0.0:
			return Response.DONE
		
		target.offset += Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		return Response.OK

@export_category("On-Start References")
## follow is called on this node on ready.
@export var initial_follow_target: Node2D
@export_category("Settings")
## The camera will look for affectors on these layers. Its not necessary for affectors
## to be on their own layer, but it would be slightly more performant if so.
@export_flags_2d_physics var affector_layer
## The camera will maintain zoom to view this amount of pixels. if set to 1280,720, then
## there will always be 1280 pixels visible even as the window size changes.
@export var virtual_size: Vector2 = Vector2(1280, 720):
	set(val):
		virtual_size = val
		_update_properties()
## Scale = no aspect ratio managing, Preserve Width = Height will be changed to match ratio,
## Preserve Height = Width will be changed to match ratio
@export_enum("Scale", "Preserve Width", "Preserve Height") var scaling_mode: int :
	set(val):
		scaling_mode = val
		_update_properties()
@export var reserved_left_space: float = 0: 
	set(val):
		reserved_left_space = val
		_update_properties()
@export var reserved_right_space: float = 0: 
	set(val):
		reserved_right_space = val
		_update_properties()
@export var reserved_top_space: float = 0: 
	set(val):
		reserved_top_space = val
		_update_properties()
@export var reserved_bottom_space: float = 0: 
	set(val):
		reserved_bottom_space = val
		_update_properties()

@export_category("Effects")
@export var process_effects_in_physics: bool = false
## If non-zero, the camera2d will tilt into its movement. Use negative to invert
## the effect
@export var tilt_into_velocity: float = 0.0
@export var max_tilt: float = 15.0
@export var max_tilt_speed: float = 200.0
## How strong the affectors affect this camera. If you want to disable affectors entirely,
## set this to 0.
@export var affector_strength: float = 1.0

var effect_stack: Array[Effect] = []
var following: Node2D
var window_size: Vector2

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_properties()
	if what == NOTIFICATION_WM_DPI_CHANGE:
		_update_properties()

func _get_affectors(world_position: Vector2) -> Array[NoteCameraAffector]:
	var affectors: Array[NoteCameraAffector] = []
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = affector_layer
	query.collide_with_bodies = false
	query.collide_with_areas = true
	
	var space = get_world_2d().direct_space_state
	var hits = space.intersect_point(query)
	
	for h in hits:
		if h["collider"] is NoteCameraAffector:
			affectors.append(h["collider"] as NoteCameraAffector)
	
	return affectors

func _reset(delta: float):
	var previous_pos = global_position+offset
	if following != null:
		global_position = following.global_position
	offset = Vector2.ZERO
	var affectors = _get_affectors(global_position)
	for aff: NoteCameraAffector in affectors:
		var affector_offset = aff.get_offset(global_position)
		global_position -= affector_offset * affector_strength
	_process_effects(delta)
	var delta_position = previous_pos-(global_position+offset)
	
	var snap_increment = Vector2(1.0/zoom.x, 1.0/zoom.y)
	global_position.x = snapped(global_position.x, snap_increment.x)
	global_position.y = snapped(global_position.y, snap_increment.y)
	
func _process_effects(delta: float):
	for i in range(effect_stack.size() - 1, -1, -1):
		var state = effect_stack[i].apply(delta, self)
		if state != Effect.Response.OK:
			effect_stack.remove_at(i)

func _update_properties():
	var size = DisplayServer.window_get_size()
	window_size = size
	zoom = Vector2(float(size.x)/virtual_size.x, float(size.y)/virtual_size.y)
	if scaling_mode == 1:
		zoom.y = zoom.x
	if scaling_mode == 2:
		zoom.x = zoom.y

func _ready() -> void:
	if initial_follow_target != null:
		follow(initial_follow_target)
	ignore_rotation = false
	_update_properties()
	get_viewport().size_changed.connect(_update_properties)
func _process(delta: float) -> void:
	if !process_effects_in_physics:
		_reset(delta)
func _physics_process(delta: float) -> void:
	if process_effects_in_physics:
		_reset(delta)

func follow(target: Node2D):
	var distance = global_position.distance_to(target.global_position)
	following = target
	global_position = target.global_position
	if distance > 100.0:
		reset_smoothing()
		reset_physics_interpolation()

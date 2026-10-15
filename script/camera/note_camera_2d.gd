extends Camera2D
class_name NoteCamera2D

class Effect extends RefCounted:
	enum Response {
		DONE,
		OK,
		ERR
	}
	func apply(delta: float, target: NoteCamera2D) -> Response:
		return Response.DONE

class ShakeEffect extends Effect:
	var max_life = 2.0
	var life = 2.0
	var shake_strength = 0.0
	var tapers: bool = true
	func _init(duration: float, power: float, taper: bool):
		life = duration
		max_life = duration
		shake_strength = power
		tapers = taper
	func apply(delta: float, target: NoteCamera2D) -> Response:
		life -= delta
		if life <= 0.0:
			return Response.DONE
		
		var shake_amount = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		if tapers:
			shake_amount *= clamp((life/max_life), 0.0, 1.0)
		
		target.offset += shake_amount
		return Response.OK

@export_category("Settings")
## The camera will look for affectors on these layers. Its not necessary for affectors
## to be on their own layer, but it would be slightly more performant if so.
@export_flags_2d_physics var affector_layer: int
## The camera will maintain zoom to view this amount of pixels. Even as the viewport
## changes size, the camera will attempt to maintain a visible resolution.
@export var virtual_size: Vector2 = Vector2(1280, 720):
	set(val):
		virtual_size = val
		_update_properties()
## If you need to multiply the zoom after it is calculated by the virtual size, you can use this.
@export var virtual_zoom: Vector2 = Vector2.ONE:
	set(val):
		virtual_zoom = val
		_update_properties()
## Scale = no aspect ratio managing, Preserve Width = Height will be changed to match ratio,
## Preserve Height = Width will be changed to match ratio
@export_enum("Scale", "Preserve Width", "Preserve Height") var scaling_mode: int :
	set(val):
		scaling_mode = val
		_update_properties()

## If true, the camera will no longer be able to move past its limits.
@export var clamp_position_to_limits: bool = true


@export_group("Effects")
@export var process_effects_in_physics: bool = false

@export_group("Tilt")
## If non-zero, the camera2d will tilt into its movement. Use negative to invert
## the effect. 
@export var tilt_into_velocity: float = 0.0
@export var max_tilt: float = 15.0
@export var max_tilt_speed: float = 200.0
## How strong the affectors affect this camera. If you want to disable affectors entirely,
## set this to 0.
@export var affector_strength: float = 1.0
@export var offset_smoothing_speed: float = 4.0

var _effect_stack: Array[Effect] = []
var _window_size: Vector2
var _affector_offset_cache: Vector2
var _previous_position: Vector2
var _auto_tilt: float = 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_properties()
	if what == NOTIFICATION_WM_DPI_CHANGE:
		_update_properties()

func _get_affectors(world_position: Vector2) -> Array[NoteCameraAffector]:
	if affector_layer == 0: return []
	var affectors: Array[NoteCameraAffector] = []
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = affector_layer
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var space = get_world_2d().direct_space_state
	var hits = space.intersect_point(query)
	
	for h in hits:
		if h["collider"] is NoteCameraAffector:
			affectors.append(h["collider"] as NoteCameraAffector)
	
	return affectors

func _reset(delta: float):
	offset = Vector2.ZERO
	## Offset is specifically ignored here, to prevent rapid state transitions
	## from offsets moving it in and out of the volumes.
	var affectors = _get_affectors(global_position)
	var local_affector_offset = Vector2.ZERO
	for aff: NoteCameraAffector in affectors:
		var affector_offset = aff.get_offset(global_position)
		local_affector_offset -= affector_offset * affector_strength
	if offset_smoothing_speed <= 0.0:
		offset += local_affector_offset
	else:
		_affector_offset_cache = note.util.smooth_toward_v2(_affector_offset_cache, local_affector_offset, offset_smoothing_speed, delta)
		offset += _affector_offset_cache
	
func _process_effects(delta: float):
	for i in range(_effect_stack.size() - 1, -1, -1):
		var state = _effect_stack[i].apply(delta, self)
		if state != Effect.Response.OK:
			_effect_stack.remove_at(i)

func _update_properties():
	var size
	if is_inside_tree():
		size = get_viewport_rect().size
	else:
		size = DisplayServer.window_get_size()
	_window_size = size
	zoom = Vector2(float(size.x)/virtual_size.x, float(size.y)/virtual_size.y)
	if scaling_mode == 1:
		zoom.y = zoom.x
	if scaling_mode == 2:
		zoom.x = zoom.y
	zoom *= virtual_zoom

func _ready() -> void:
	ignore_rotation = false
	_update_properties()
	get_viewport().size_changed.connect(_update_properties)

func _work(delta: float):
	_reset(delta)
	_process_effects(delta)
	
	var delta_position = _previous_position-get_screen_center_position()
	
	if !is_equal_approx(tilt_into_velocity, 0.0):
		_auto_tilt += delta_position.x * tilt_into_velocity
		_auto_tilt = clamp(_auto_tilt, -max_tilt, max_tilt)
		rotation_degrees = _auto_tilt
		_auto_tilt = note.util.smooth_toward(_auto_tilt, 0.0, max_tilt_speed, delta)
	else:
		_auto_tilt = 0.0
	
	_previous_position = get_screen_center_position()

func _process(delta: float) -> void:
	if !process_effects_in_physics:
		_work(delta)
func _physics_process(delta: float) -> void:
	if process_effects_in_physics:
		_work(delta)

func shake(duration: float, strength: float, taper: bool = true):
	var new_effect = ShakeEffect.new(duration, strength, taper)
	add_effect(new_effect)
func add_effect(new_effect: Effect):
	_effect_stack.push_front(new_effect)

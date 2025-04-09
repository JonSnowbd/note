@tool
@icon("res://addons/note/texture/icon/cute_sprite.svg")
extends Node2D
class_name CuteSprite2D

static var identity_pool: int = 0

class AnimationItem extends RefCounted:
	var texture_reference: BaseCuteTexture2D = null
	var priority_offset: int = 0
	var duration: float = 0.0
	var current_timer: float = 0.0
	var cancel_keyword: String = ""
	var custom_motion = null
	var unique_id: int = -1

## This signal is emitted when we procedurally detect height going from high to low quick enough.
## Requires generate_steps to be enabled on the sprite.
signal step()

@export_group("Sprite Settings")
## This is the default sprite when no overrides are running.
@export var default_texture: BaseCuteTexture2D
## The sprite must be traveling this speed in pixels per second on average
## For the highest magnitude of sprite movement.
@export var max_magnitude_velocity: float = 100.0
## If true, auto mode is active, and velocity+facing will be derived based on
## node changes such as global_position.
@export var automatically_pose: bool = true
## If true, we will generate step signals for when we detect a 'step'. Off by default to save cycles.
@export var generate_steps: bool = false

@export_group("In-Editor Preview")
## Enables previewing of the selected motion settings in editor.
@export var preview_enabled: bool = false
## The preview, when on, will have this set as the velocity.
@export var preview_velocity: Vector2 = Vector2.ZERO
## The preview, when on will be looking at this. (relative to the node.)
@export var preview_look_direction: Vector2 = Vector2.ZERO
@export_range(0.0, 1.0) var preview_tool_alpha: float = 0.5
@export var preview_tool_size: float = 4.0

@export_group("Scaling")
@export var time_scale: float = 1.0
## Each motion will use this as an approximation of how much the sprite should move, at most.
## This is important for scaling the feel of small and large sprites.
@export var approximate_motion_px: float = 4.0
## Each motion will use this as an approximation of how much the sprite should rotate, at most.
## This is important for scaling the feel of small and large sprites.
@export var approximate_angular_motion_deg: float = 12.5
## How fast it transitions from idle to movement, expressed in 
## transition per second. 6.0 means it will take 1/6th of a second. Higher is faster.
@export var state_transfer_speed: float = 6.0
## overall cycle speed.
@export var cycle_speed: float = 1.0
## Idle motion will be multiplied by this.
@export var idle_exaggeration: float = 1.0
## Idle motion's clock cycle will be this much faster. 2.0 = 2x
@export var idle_speed: float = 1.0
## Moving motion's translations will be multiplied by this
@export var motion_exaggeration: float = 1.0
## Moving motion's clock cycle will be this much faster. 2.0 = 2x
@export var motion_speed: float = 1.0

@export_group("Shadow")
## This should be a white circle on a shared sheet with your characters for better texture swaps.
@export var shadow_sprite: Texture2D
@export var shadow_color: Color
@export_range(0.0, 1.0) var shadow_obliquity: float = 0.6
@export_range(0.0, 2.0) var shadow_scale: float = 1.0
## The height at which the shadow is no longer visible
@export var shadow_fade_height: float = 8.0

@export_group("Auto Mode Settings")
## Store n frames of velocity, and using this as an average for auto-pose.
@export var smoothing_frames: int = 5
@export var use_physics_process: bool = true
## If assigned, the sprite will always face this other node, when auto posing.
@export var autopose_focus: Node2D
## If assigned, autopose will use the physics body's velocity directly.
@export var parent_body: PhysicsBody2D

@export_group("Advanced")
## How fast we must be moving in auto mode for facing to be recalculated.
@export var min_velocity_for_facing_recalc: float = 0.1
## How many frames back we look to see if we 'stepped' by going from a height, to the floor.
@export var height_sample_frames: int = 10
## If we get THIS high, trigger a step if we go `step_lower_bound` low.
@export var step_upper_bound: float = 2.0
## If in the frame window, we get THIS low, after going `step_upper_bound` high, step.
@export var step_lower_bound: float = 0.1


var previous_position: Vector2
var velocity_samples: Array[Vector2]

var idle_motion_cycle: float = 0.0
var motion_motion_cycle: float = 0.0
var general_cycle: float = 0.0
var current_power: float = 0.0
var current_leaning: float = 0.0

var timeout_timer: float = 0.0
var timeout_multiplier: float = 1.0

var framedata: CutePoseFrameData

var mark_clean: bool = false
var texture_stack: Array[AnimationItem] = []
var effect_cache: Dictionary = {}

var _current_effect: AnimationItem = null

var heights: Array[float] = []

## Controls the animation effect, and transitions between idle and motion expression based on
## magnitude
var velocity: Vector2 = Vector2.ZERO
## Relative to the node. (1,0) will always look right for example. Controls which
## sprite is used for direction and flipping_h. For example looking up, down, left or right.
var look_at_position: Vector2 = Vector2.ZERO

func _ready():
	previous_position = global_position
	framedata = CutePoseFrameData.new()

func get_current_texture() -> BaseCuteTexture2D:
	for tex: AnimationItem in texture_stack:
		if tex.texture_reference != null:
			return tex.texture_reference
	return default_texture as BaseCuteTexture2D

func _process(delta):
	delta *= time_scale
	if Engine.is_editor_hint():
		if preview_enabled:
			velocity = preview_velocity
			look_at_position = preview_look_direction
			apply_pose(delta)
		else:
			reset_values()
	else:
		if automatically_pose and !use_physics_process:
			feed(delta)
		for item in texture_stack:
			if item.duration < 0.0:
				continue
			item.current_timer -= delta
			if item.current_timer <= 0.0:
				mark_clean = true
		if mark_clean:
			clean_stack()
		if automatically_pose:
			auto_mode_calculation()
		apply_pose(delta)
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	delta *= time_scale
	if Engine.is_editor_hint() == false and automatically_pose and use_physics_process:
		feed(delta)
	if Engine.is_editor_hint() == false and generate_steps:
		heights.append(framedata.height)
		while len(heights) > height_sample_frames:
			heights.pop_front()
		var raised_enough: bool = false
		for h: float in heights:
			if h > step_upper_bound:
				raised_enough = true
			if raised_enough and h <= step_lower_bound:
				step.emit()
				heights.clear()
## Like push texture, but for adding custom motion offsets. If duration is less than zero, the effect will not expire, if you assign it a keyword
## you can instead call for its deletion via that.
func push_effect(effect: Callable, duration: float = -1.0, keyword: String = "", priority_offset: int = 0):
	var new_fx = AnimationItem.new()
	new_fx.priority_offset = 0
	new_fx.cancel_keyword = keyword
	new_fx.duration = duration
	new_fx.current_timer = duration
	new_fx.custom_motion = effect
	new_fx.unique_id = identity_pool
	identity_pool += 1
	texture_stack.append(new_fx)
	texture_stack.sort_custom(sort_method)
## If duration is less than zero, the texture will not expire, if you assign it a keyword
## you can instead call for its deletion via that.
func push_texture(new_texture: BaseCuteTexture2D, duration: float = -1.0, keyword: String = "", priority_offset: int = 0):
	var new_tex = AnimationItem.new()
	new_tex.priority_offset = 0
	new_tex.cancel_keyword = keyword
	new_tex.duration = duration
	new_tex.current_timer = duration
	new_tex.texture_reference = new_texture
	new_tex.unique_id = identity_pool
	identity_pool += 1
	texture_stack.append(new_tex)
	texture_stack.sort_custom(sort_method)
## If you pushed a texture with a keyword, you can delete it now with this.
func clear_texture(keyword: String):
	var clear: bool = false
	for tex: AnimationItem in texture_stack:
		if tex.cancel_keyword == keyword:
			clear = true
			tex.duration = 0.0
			tex.current_timer = 0.0
	if clear:
		clean_stack()
## When called, will make the sprite completely static, smoothly, for the duration.
func timeout(time: float):
	timeout_timer = time

## Do not call, internal process. Pushes everything forward a tick and calculates the pose.
func apply_pose(delta: float):
	var target_power = clamp(remap(velocity.length(), 0.0, max_magnitude_velocity, 0.0, 1.0),0.0, 1.0)
	var sprite = get_current_texture()
	
	if timeout_timer > 0.0:
		timeout_multiplier = move_toward(timeout_multiplier, 0.0, state_transfer_speed*delta)
		current_power = move_toward(current_power, 0.0, state_transfer_speed*delta)
		current_leaning = move_toward(current_leaning, 0.0, state_transfer_speed*delta)
		timeout_timer -= delta
	else:
		var clamped_vel = velocity
		if clamped_vel.length() > max_magnitude_velocity:
			clamped_vel = clamped_vel.normalized() * max_magnitude_velocity
		timeout_multiplier = move_toward(timeout_multiplier, 1.0, state_transfer_speed*delta)
		current_power = move_toward(current_power, target_power, state_transfer_speed*delta)
		current_leaning = move_toward(current_leaning, clamp(clamped_vel.x / max_magnitude_velocity, -1.0, 1.0), state_transfer_speed*delta)
	
	reset_values()
	general_cycle += delta * cycle_speed
	idle_motion_cycle += (delta*(1.0-current_power)) * idle_speed * cycle_speed
	motion_motion_cycle += (delta*current_power) * motion_speed * cycle_speed
	if sprite != null:
		add_motion_values(sprite.idle_motion, idle_motion_cycle, (1.0-current_power) * idle_exaggeration * timeout_multiplier)
		add_motion_values(sprite.moving_motion, motion_motion_cycle, current_power * motion_exaggeration)
		for item: AnimationItem in texture_stack:
			if item.custom_motion != null and item.custom_motion is Callable:
					_current_effect = item
					item.custom_motion.call(self)
		_current_effect = null
func reset_values():
	framedata.height = 0.0
	framedata.rotational_offset = 0.0
	framedata.positional_offset = Vector2.ZERO
	framedata.scale_offset = Vector2.ZERO
## Called in auto mode, determines 
func auto_mode_calculation():
	velocity = Vector2.ZERO
	for vel in velocity_samples:
		velocity += vel
	velocity /= len(velocity_samples)
	if autopose_focus != null and is_instance_valid(autopose_focus) and autopose_focus.is_inside_tree():
		look_at_position = autopose_focus.global_position - global_position
	elif velocity.length() > min_velocity_for_facing_recalc:
		look_at_position = velocity.normalized()*5.0

func feed(delta):
	if Engine.is_editor_hint() == false and automatically_pose:
		if parent_body == null or parent_body is AnimatableBody2D:
			var diff = (global_position - previous_position)/delta
			velocity_samples.append(diff)
		elif parent_body is CharacterBody2D:
			velocity_samples.append(parent_body.velocity)
		elif parent_body is RigidBody2D:
			velocity_samples.append(parent_body.linear_velocity)
		while len(velocity_samples) > smoothing_frames:
			velocity_samples.pop_front()
	previous_position = global_position

func sort_method(a: AnimationItem, b: AnimationItem) -> int:
	if a.texture_reference == null or b.texture_reference == null:
		return 0
	return (a.texture_reference.priority+a.priority_offset) < (b.texture_reference.priority+b.priority_offset)

## Internal method, used to filter effects and textures.
func filter_method(object: AnimationItem) -> bool:
	if object.duration < 0.0:
		return true
	var should_live = object.current_timer >= 0.0
	if !should_live:
		effect_cache.erase(object.unique_id)
	return should_live

## For use in custom effects, use this for state. Cleared when effect is over.
func effect_cache_get(key: String, default_val = null):
	if effect_cache.has(_current_effect.unique_id):
		if effect_cache[_current_effect.unique_id].has(key):
			return effect_cache[_current_effect.unique_id][key]
	return default_val
## For use in custom effects, use this for runtime state. Cleared when effect is over.
func effect_cache_set(key: String, val):
	if effect_cache.has(_current_effect.unique_id) == false:
		effect_cache[_current_effect.unique_id] = {}
	effect_cache[_current_effect.unique_id][key] = val
## The remaining time in the effect, and INF if infinite.
func effect_time_left() -> float:
	if _current_effect.duration < 0.0:
		return INF
	return _current_effect.current_timer
## Returns 0.0 -> 1.0 how into the motion animation this sprite is. Useful for writing your own motion
## animation.
func effect_get_motion_power() -> float:
	return current_power
## Returns 0.0 -> 1.0 how into the idle animation this sprite is. Useful for writing your own idle
## animation.
func effect_get_idle_power() -> float:
	return 1.0 - current_power
## Useful to check. If true this effect is permanent, which is not desirable for some effects, no backflips last forever my son.
func effect_is_infinite() -> bool:
	return _current_effect.duration < 0.0
## From 0.0 -> 1.0 how complete this effect is.
func effect_completion() -> float:
	if _current_effect.duration < 0.0:
		return 0.0
	return 1.0-(_current_effect.current_timer / _current_effect.duration)
## From 1.0 -> 0.0, based on life time.
func effect_inverse_completion() -> float:
	if _current_effect.duration < 0.0:
		return 1.0
	return (_current_effect.current_timer / _current_effect.duration)
## Translates the sprite(this is visual only, no transforms are actually moved)
func effect_translate(translation: Vector2):
	framedata.positional_offset += translation
## scales the sprite(this is visual only, no transforms are actually moved)
func effect_scale(scalar: Vector2):
	framedata.scale_offset += scalar
## Rotates the sprite(this is visual only, no transforms are actually rotated)
func effect_rotate(rot_deg: float):
	framedata.rotational_offset += rot_deg
## Lifts the sprite(this is visual only, no transforms are actually moved)
## Prefer this for 'vertical' movement like jumps, the shadow reacts to lift movement.
func effect_lift(amount: float):
	framedata.height += amount
## Every mutation in one call. (these are visual only, no transforms are actually modified)
func effect_mutate(translation: Vector2 = Vector2.ZERO, rot_deg: float = 0.0, scale_mod: Vector2 = Vector2.ZERO, lift: float = 0.0):
	framedata.positional_offset += translation
	framedata.rotational_offset += rot_deg
	framedata.height += lift
	framedata.scale_offset += scale_mod

func clean_stack():
	texture_stack = texture_stack.filter(filter_method)
	texture_stack.sort_custom(sort_method)
	mark_clean = false
func _draw():
	var sprite = get_current_texture()
	if framedata == null:
		framedata = CutePoseFrameData.new()
		return
	if sprite == null:
		return
	if Engine.is_editor_hint():
		if preview_enabled:
			draw_line(Vector2.ZERO, velocity.normalized() * current_power * 10.0, Color(1.0, 0.7, 0.7, preview_tool_alpha), preview_tool_size)
			draw_line(Vector2.ZERO, look_at_position, Color(0.4, 0.7, 0.9, preview_tool_alpha), preview_tool_size)
			pass
	if shadow_sprite != null and shadow_color.a > 0.0:
		var shadow_scale_from_height = clamp(remap(framedata.height, 0.0, shadow_fade_height, 1.0, 0.4), 0.4, 1.0)
		var s_scale = Vector2(shadow_scale, shadow_scale * shadow_obliquity) * shadow_scale_from_height
		draw_set_transform(framedata.positional_offset-shadow_sprite.get_size()*s_scale*0.5, 0.0, s_scale)
		var true_shadow_color = shadow_color
		true_shadow_color.a *= shadow_scale_from_height
		draw_texture(shadow_sprite, Vector2.ZERO, true_shadow_color)

	var texture = sprite.get_appropriate_texture(rad_to_deg(look_at_position.angle()))
	if texture == null:
		return
	var matrix = Transform2D.IDENTITY
	matrix = matrix.scaled(Vector2.ONE+framedata.scale_offset)
	matrix = matrix.translated(((texture.get_size()*-0.5) * (Vector2.ONE+framedata.scale_offset)) + sprite.offset)
	if sprite.auto_flip and look_at_position.x < 0.0:
		matrix = matrix.scaled(Vector2(-1.0, 1.0))
	matrix = matrix.rotated(deg_to_rad(framedata.rotational_offset))
	matrix = matrix.translated(framedata.positional_offset+Vector2(0, -framedata.height))
	draw_set_transform_matrix(matrix)
	draw_texture(texture, Vector2.ZERO)

func add_motion_values(type: BaseCuteTexture2D.MotionType, cycle: float, power: float) -> void:
	match type:
		BaseCuteTexture2D.MotionType.Sway:
			framedata.rotational_offset += (sin(cycle) * approximate_angular_motion_deg) * power
		BaseCuteTexture2D.MotionType.HumanWalk:
			var theta = sin(cycle * (12.5))
			var angle = current_leaning * -approximate_angular_motion_deg * power
			var y = abs(theta * (approximate_motion_px*power))
			framedata.height += y
			framedata.rotational_offset -= angle
		BaseCuteTexture2D.MotionType.Breath:
			framedata.scale_offset.y += sin(cycle)*0.1*power
		BaseCuteTexture2D.MotionType.Hop:
			framedata.height += abs(sin(cycle*approximate_motion_px))*power
		BaseCuteTexture2D.MotionType.LeanIn:
			framedata.rotational_offset -= (current_leaning * -10.0) * power
		BaseCuteTexture2D.MotionType.LeanOut:
			framedata.rotational_offset += (current_leaning * -10.0) * power
		BaseCuteTexture2D.MotionType.Wiggle:
			framedata.positional_offset.x += (sin(cycle*20.0) * 1.0 * power)
			framedata.positional_offset.x += (sin(cycle*7.0) * .5 * power)
			framedata.height += (sin(cycle*2.0) * 1.5 * power)
			

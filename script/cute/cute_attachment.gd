@tool
extends Node2D
class_name CuteAttachment2D

@export_group("References")
@export var work_in_physics_process: bool = true
## Optional, but more performant if assigned. Hands are created
## as siblings of the cute sprite for proper z layer.
@export var cute_sprite_target: CuteSprite2D
@export var owner_override: Node2D
@export var sprite: Texture2D
@export var sprite_rotation: float = 0.0

@export var origin: Vector2 = Vector2(0.5, 0.5)
@export var start_stowed: bool = false

func _restart():
	_clean_hands_rid()
	_ensure_hands_rid()
@export_tool_button("Restart") var _restart_system_action = _restart

@export_group("Shadow")
@export var shadow: Texture2D
@export var shadow_base_color: Color
@export var shadow_scale: Vector2 = Vector2.ONE
@export var shadow_raise_fade: float = 10.0

@export_group("Inheritance")
@export var inherit_rotation: float = 1.0
@export var inherit_position: float = 1.0
@export var inherit_raise: float = 1.0

@export_group("General Pose")
@export var facing_offset: float
@export var distance: float = 6.0
@export var raise: float = 4.75
@export var alpha: float = 1.0

var i_rid: RID
var i_root_rid: RID
var _last_valid_look: Vector2 = Vector2.RIGHT
## The last known offset of the base object(the shadow) from the root.
var _cached_position: Vector2
## The last known offset of the real object(the hand/item) from the shadow
var _cached_object_offset: Vector2

func _find_cute_sprite() -> CuteSprite2D:
	var parent = get_parent() 
	while parent != null:
		for c in parent.get_children(true):
			if c is CuteSprite2D:
				return c
		parent = parent.get_parent()
	return null
func _set_sprite(rid: RID, sprite: Texture2D):
	RenderingServer.canvas_item_clear(rid)
	if sprite != null:
		var siz = sprite.get_size()
		var rect = Rect2(-siz.x*origin.x, -siz.y*origin.y, siz.x, siz.y)
		if sprite is AtlasTexture:
			RenderingServer.canvas_item_add_texture_rect_region(rid, rect, sprite.get_rid(), sprite.region)
		else:
			RenderingServer.canvas_item_add_texture_rect(rid, rect, sprite.get_rid())
func _clean_hands_rid():
	if i_rid.is_valid():
		RenderingServer.canvas_item_clear(i_rid)
		RenderingServer.free_rid(i_rid)
		i_rid = RID()
	if i_root_rid.is_valid():
		RenderingServer.canvas_item_clear(i_root_rid)
		RenderingServer.free_rid(i_root_rid)
		i_root_rid = RID()
func _ensure_hands_rid():
	if !i_root_rid.is_valid():
		i_root_rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(i_root_rid, owner_override.get_canvas_item())
		_set_sprite(i_root_rid, shadow)
	if !i_rid.is_valid():
		i_rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(i_rid, i_root_rid)
		_set_sprite(i_rid, sprite)
func _with_a(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, a)
func _enter_tree() -> void:
	if owner_override == null:
		var sprite = _find_cute_sprite()
		if sprite != null:
			owner_override = sprite.get_parent()
	_ensure_hands_rid()
	if start_stowed:
		stow(0.0)
func _exit_tree() -> void:
	_clean_hands_rid()
func _work(delta: float):
	if !visible or cute_sprite_target == null:
		return
	if !i_rid.is_valid() or !i_root_rid.is_valid():
		return
	
	var lookat = cute_sprite_target.look_at_position
	if lookat.length() < 0.1:
		lookat = _last_valid_look
	var forward = cute_sprite_target.look_at_position.normalized().angle()+facing_offset
	var offset = cute_sprite_target.framedata.positional_offset
	
	# Do the left hand thing.
	var raise = raise+(cute_sprite_target.framedata.height*inherit_raise)
	var angle = forward+facing_offset
	if sprite != null:
		#Organize root node
		var root_transform = Transform2D.IDENTITY\
		.scaled(shadow_scale)\
		.translated(Vector2.RIGHT.rotated(angle)*(distance))
		RenderingServer.canvas_item_set_transform(i_root_rid, root_transform)
		_cached_position = root_transform.origin
		
		# Colorize root node's shadow
		if shadow != null:
			var real_alpha = lerp(shadow_base_color.a, 0.0, clamp(raise/shadow_raise_fade, 0.0, 1.0)) * alpha
			if (raise) < 0.0:
				real_alpha = 0.0
			RenderingServer.canvas_item_set_self_modulate(i_root_rid, _with_a(shadow_base_color, real_alpha))
		
		# Set hands raised position above root.
		var bit_transform = Transform2D.IDENTITY\
		.rotated(angle+sprite_rotation)\
		.translated(Vector2(0, -raise))\
		.scaled(Vector2.ONE/shadow_scale)
		RenderingServer.canvas_item_set_self_modulate(i_rid, Color(1.0, 1.0, 1.0, alpha))
		RenderingServer.canvas_item_set_transform(i_rid, bit_transform)
		_cached_object_offset = bit_transform.origin
		
	_last_valid_look = lookat
func _process(delta: float) -> void:
	if !work_in_physics_process:
		_work(delta)
func _physics_process(delta: float) -> void:
	if work_in_physics_process:
		_work(delta)

func reset_pose():
	facing_offset = 0.0
	distance = 4.0
	raise = 4.75
	alpha = 1.0
## Will create a tween, and subtween it if provided a root tween.
## The attachment will then fade away and fall down
func stow(duration: float = 0.2, stem_tween: Tween = null) -> Tween:
	if duration <= 0.0:
		alpha = 0.0
		distance = 0.25
		return null
	var t: Tween = create_tween()
	if stem_tween != null:
		stem_tween.tween_subtween(stem_tween)
	t.set_parallel(true)
	t.tween_property(self, "alpha", 0.0, duration)
	t.tween_property(self, "distance", 0.25, duration)
	return t
func unstow():
	pass
func get_real_facing() -> float:
	if cute_sprite_target == null: return 0.0
	return cute_sprite_target.look_at_position.normalized().angle()+facing_offset
## Return the base(read: shadows) offset from the root node
func get_real_root_position() -> Vector2:
	return _cached_position
## Return the items(read: hand, item etc) offset from the base(the shadow)
func get_real_object_offset() -> Vector2:
	return _cached_object_offset

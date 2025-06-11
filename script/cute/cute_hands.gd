@tool
extends Node2D
class_name CuteHands2D

@export_group("References")
@export var work_in_physics_process: bool = true
## Optional, but more performant if assigned. Hands are created
## as siblings of the cute sprite for proper z layer.
@export var cute_sprite_target: CuteSprite2D
@export var owner_override: Node2D
@export var item_sprite: Texture2D
@export var item_sprite_rotation: float = 0.0
@export var left_hand_sprite: Texture2D
@export var left_hand_sprite_rotation: float = 0.0
@export var right_hand_sprite: Texture2D
@export var right_hand_sprite_rotation: float = 0.0

@export var hand_origin: Vector2 = Vector2(0.5, 0.5)
@export var item_origin: Vector2 = Vector2(0.5, 0.5)


func _restart():
	_clean_hands_rid()
	_ensure_hands_rid()
@export_tool_button("Restart") var _restart_system_action = _restart

@export_group("Hand Shadow")
@export var hand_shadow: Texture2D
@export var hand_shadow_base_color: Color
@export var hand_shadow_scale: Vector2 = Vector2.ONE
@export var hand_shadow_raise_fade: float = 10.0
@export_group("Item Shadow")
@export var item_shadow: Texture2D
@export var item_shadow_base_color: Color
@export var item_shadow_scale: Vector2 = Vector2.ONE
@export var item_shadow_raise_fade: float = 10.0

@export_group("Inheritance")
@export var inherit_rotation: float = 1.0
@export var inherit_position: float = 1.0
@export var inherit_raise: float = 1.0


@export_group("General Pose")
@export var hands_facing_offset: float
@export var hands_distance: float = 6.0
@export var hands_spread: float = 1.3
@export var hands_raise: float = 4.75

@export_group("Left Hand")
@export var left_hand_facing_offset: float = 0.0
@export var left_hand_raise: float = 0.0
@export var left_hand_distance: float = 0.0
@export_group("Right Hand")
@export var right_hand_facing_offset: float = 0.0
@export var right_hand_raise: float = 0.0
@export var right_hand_distance: float = 0.0
@export_group("Item")
@export var item_handedness: float = 0.5
@export var item_distance: float = 0.0
@export var item_spin: float = 0.0
@export var item_facing_offset: float = 0.0
@export var item_raise: float = 0.0

var i_rid: RID
var i_root_rid: RID
var l_hand_rid: RID
var l_root_rid: RID
var r_hand_rid: RID
var r_root_rid: RID

var _last_valid_look: Vector2 = Vector2.RIGHT
var _cached_l_hand_pos: Vector2
var _cached_r_hand_pos: Vector2
var _cached_item_pos: Vector2

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
		var rect = Rect2(-siz.x*hand_origin.x, -siz.y*hand_origin.y, siz.x, siz.y)
		if sprite == item_sprite:
			rect = Rect2(-siz.x*item_origin.x, -siz.y*item_origin.y, siz.x, siz.y)
		if sprite is AtlasTexture:
			RenderingServer.canvas_item_add_texture_rect_region(rid, rect, sprite.get_rid(), sprite.region)
		else:
			RenderingServer.canvas_item_add_texture_rect(rid, rect, sprite.get_rid())
func _clean_hands_rid():
	if l_hand_rid.is_valid():
		RenderingServer.canvas_item_clear(l_hand_rid)
		RenderingServer.free_rid(l_hand_rid)
		l_hand_rid = RID()
	if r_hand_rid.is_valid():
		RenderingServer.canvas_item_clear(r_hand_rid)
		RenderingServer.free_rid(r_hand_rid)
		r_hand_rid = RID()
	if r_root_rid.is_valid():
		RenderingServer.canvas_item_clear(r_root_rid)
		RenderingServer.free_rid(r_root_rid)
		r_root_rid = RID()
	if l_root_rid.is_valid():
		RenderingServer.canvas_item_clear(l_root_rid)
		RenderingServer.free_rid(l_root_rid)
		l_root_rid = RID()
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
		_set_sprite(i_root_rid, hand_shadow)
	if !i_rid.is_valid():
		i_rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(i_rid, i_root_rid)
		_set_sprite(i_rid, item_sprite)
	if !l_root_rid.is_valid():
		l_root_rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(l_root_rid, owner_override.get_canvas_item())
		_set_sprite(l_root_rid, hand_shadow)
	if !r_root_rid.is_valid():
		r_root_rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(r_root_rid, owner_override.get_canvas_item())
		_set_sprite(r_root_rid, hand_shadow)
	if !l_hand_rid.is_valid():
		l_hand_rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(l_hand_rid, l_root_rid)
		_set_sprite(l_hand_rid, left_hand_sprite)
	if !r_hand_rid.is_valid():
		r_hand_rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(r_hand_rid, r_root_rid)
		_set_sprite(r_hand_rid, right_hand_sprite)
func _with_a(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, a)
func _enter_tree() -> void:
	if owner_override == null:
		var sprite = _find_cute_sprite()
		if sprite != null:
			owner_override = sprite.get_parent()
	_ensure_hands_rid()
func _exit_tree() -> void:
	_clean_hands_rid()
func _work(delta: float):
	if !visible or cute_sprite_target == null:
		return
	if !l_hand_rid.is_valid() or !r_hand_rid.is_valid():
		return
	
	var lookat = cute_sprite_target.look_at_position
	if lookat.length() < 0.1:
		lookat = _last_valid_look
	var forward = cute_sprite_target.look_at_position.normalized().angle()+hands_facing_offset
	var offset = cute_sprite_target.framedata.positional_offset
	var halfspread = hands_spread * 0.5
	
	# Do the left hand thing.
	var lraise = hands_raise+left_hand_raise+(cute_sprite_target.framedata.height*inherit_raise)
	var lhand_angle = forward+left_hand_facing_offset-halfspread
	if left_hand_sprite != null:
		#Organize root node
		var root_transform = Transform2D.IDENTITY\
		.scaled(hand_shadow_scale)\
		.translated(Vector2.RIGHT.rotated(lhand_angle)*(hands_distance+left_hand_distance))
		RenderingServer.canvas_item_set_transform(l_root_rid, root_transform)
		
		# Colorize root node's shadow
		if hand_shadow != null:
			var alpha = lerp(hand_shadow_base_color.a, 0.0, clamp(lraise/hand_shadow_raise_fade, 0.0, 1.0))
			if (lraise) < 0.0:
				alpha = 0.0
			RenderingServer.canvas_item_set_self_modulate(l_root_rid, _with_a(hand_shadow_base_color, alpha))
		
		# Set hands raised position above root.
		var hand_transform = Transform2D.IDENTITY\
		.rotated(lhand_angle+left_hand_sprite_rotation)\
		.translated(Vector2(0, -lraise))\
		.scaled(Vector2.ONE/hand_shadow_scale)
		
		_cached_l_hand_pos = owner_override.to_global(hand_transform.origin)
		RenderingServer.canvas_item_set_transform(l_hand_rid, hand_transform)
		# Do the right hand thing.
	var rraise = hands_raise+right_hand_raise+(cute_sprite_target.framedata.height*inherit_raise)
	var rhand_angle = forward+right_hand_facing_offset+halfspread
	if right_hand_sprite != null:
		#Organize root node
		var root_transform = Transform2D.IDENTITY\
		.scaled(hand_shadow_scale)\
		.translated(Vector2.RIGHT.rotated(rhand_angle)*(hands_distance+right_hand_distance))
		RenderingServer.canvas_item_set_transform(r_root_rid, root_transform)
		
		# Colorize root node's shadow
		if hand_shadow != null:
			var alpha = lerp(hand_shadow_base_color.a, 0.0, clamp(rraise/hand_shadow_raise_fade, 0.0, 1.0))
			if (rraise) < 0.0:
				alpha = 0.0
			RenderingServer.canvas_item_set_self_modulate(r_root_rid, _with_a(hand_shadow_base_color, alpha))
		
		# Set hands raised position above root.
		var hand_transform = Transform2D.IDENTITY\
		.rotated(rhand_angle+right_hand_sprite_rotation)\
		.translated(Vector2(0, -rraise))\
		.scaled(Vector2.ONE/hand_shadow_scale)
		
		_cached_r_hand_pos = owner_override.to_global(hand_transform.origin)
		RenderingServer.canvas_item_set_transform(r_hand_rid, hand_transform)
	if item_sprite != null:
		#Organize root node
		var raise = lerp(lraise, rraise, item_handedness)+item_raise
		var angle = lerp(lhand_angle, rhand_angle, item_handedness)+item_facing_offset
		var distance = hands_distance+lerp(left_hand_distance,right_hand_distance,item_handedness)+item_distance
		var root_transform = Transform2D.IDENTITY\
		.scaled(item_shadow_scale)\
		.translated(Vector2.RIGHT.rotated(angle)*distance)
		RenderingServer.canvas_item_set_transform(i_root_rid, root_transform)
		
		# Colorize root node's shadow
		if item_shadow != null:
			var alpha = lerp(item_shadow_base_color.a, 0.0, clamp(raise/item_shadow_raise_fade, 0.0, 1.0))
			if (raise) < 0.0:
				alpha = 0.0
			RenderingServer.canvas_item_set_self_modulate(i_root_rid, _with_a(item_shadow_base_color, alpha))
		
		# Set hands raised position above root.
		var item_transform = Transform2D.IDENTITY\
		.rotated(angle+item_sprite_rotation+item_spin)\
		.translated(Vector2(0, -raise))\
		.scaled(Vector2.ONE/item_shadow_scale)
		_cached_item_pos = owner_override.to_global(item_transform.origin)
		RenderingServer.canvas_item_set_transform(i_rid, item_transform)
	_last_valid_look = lookat
func _process(delta: float) -> void:
	if !work_in_physics_process:
		_work(delta)
func _physics_process(delta: float) -> void:
	if work_in_physics_process:
		_work(delta)

func get_left_hand_position() -> Vector2:
	return _cached_l_hand_pos
func get_right_hand_position() -> Vector2:
	return _cached_r_hand_pos
func get_item_position() -> Vector2:
	return _cached_item_pos
func reset_pose():
	inherit_rotation = 1.0
	inherit_position = 1.0
	inherit_raise = 1.0
	hands_facing_offset = 0.0
	hands_distance = 4.0
	hands_spread = 1.3
	hands_raise = 4.75
	left_hand_facing_offset = 0.0
	left_hand_raise = 0.0
	left_hand_distance = 0.0
	right_hand_facing_offset = 0.0
	right_hand_raise = 0.0
	right_hand_distance = 0.0
	item_handedness = 0.5
	item_distance = 0.0
	item_spin = 0.0
	item_facing_offset = 0.0
	item_raise = 0.0

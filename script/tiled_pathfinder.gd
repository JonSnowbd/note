@tool
extends Node2D
class_name TiledPathfinder

## Add children to this to mark starting zones.

enum TileStatus {
	NEVER,
	OCCUPIED,
	FREE
}

var finder: AStarGrid2D
## This is the statically built layers, should include stuff that will never change.
## The world will be explored with this mask, marking what tiles can be 
@export_flags_2d_physics var static_layer_mask: int = 0
## This is the dynamically searched layer. After compiling, any obstructions in this
## masks layers will be marked as temporarily occupied.
@export_flags_2d_physics var dynamic_layer_mask: int = 0
@export var agent_radius: float = 4.0
@export var region: Rect2i : 
	set(val):
		region = val
		queue_redraw()
@export var alignment: TileMapLayer : 
	set(val):
		alignment = val
		queue_redraw()
@export var static_checks_per_frame: int = 100
@export var dynamic_checks_per_frame: int = 50

var walkable: Dictionary[Vector2i,TileStatus] = {}
var frontier: Array[Vector2i] = []
var current: Vector2i
var running: bool = true
var shape_rid: RID
var fix_flip: bool = true


var dynamic_index: int = 0
var dynamic_cache: Array[Vector2i] = []

func is_walkable(coord: Vector2i) -> bool:
	if walkable.has(coord):
		return walkable[coord] == TileStatus.FREE
	return false
func is_in_bounds(coord: Vector2i) -> bool:
	return coord.x >= region.position.x and coord.y >= region.position.y \
	   and coord.x < region.position.x+region.size.x and coord.y < region.position.y+region.size.y
func pathfind(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	return finder.get_point_path(from, to, true)
func pathfind_world_pos(from_world: Vector2i, to_world: Vector2i) -> PackedVector2Array:
	var from = _world_position_to_tile_position(from_world)
	var to = _world_position_to_tile_position(to_world)
	return pathfind(from, to)
func path_expand(original_path: PackedVector2Array) -> Array[Vector2]:
	var arr: Array[Vector2] = []
	var ts = Vector2(alignment.tile_set.tile_size.x,alignment.tile_set.tile_size.y)
	var hs = ts * 0.5
	for i in original_path:
		arr.append((i*ts)+hs)
	return arr

func _is_clear(pos: Vector2i, mask: int) -> bool:
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape_rid = shape_rid
	query.collision_mask = mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var size = alignment.tile_set.tile_size
	
	var transformed_pos = Vector2(pos.x*size.x+(size.x*0.5), pos.y*size.y+(size.y*0.5))
	query.transform = Transform2D.IDENTITY.translated(alignment.to_global(transformed_pos))
	
	var hits = space.intersect_shape(query, 1)
	return len(hits) == 0

func is_ready_to_path() -> bool:
	if running or fix_flip: return false
	return true

## Returns the next move needed to get to the target.
func path_get_next_move(current: Vector2i, target: Vector2i) -> Vector2i:
	return Vector2i.ZERO

func _add_frontier(coord: Vector2i):
	if walkable.has(coord):
		return
	if is_in_bounds(coord):
		frontier.append(coord)

func _dynamic_check(coord: Vector2i):
	if !walkable.has(coord):
		return
	var clear = _is_clear(coord, dynamic_layer_mask)
	if clear:
		if walkable[coord] == TileStatus.OCCUPIED:
			walkable[coord] = TileStatus.FREE
			finder.set_point_solid(coord, false)
			queue_redraw()
	else:
		if walkable[coord] == TileStatus.FREE:
			walkable[coord] = TileStatus.OCCUPIED
			finder.set_point_solid(coord, true)
			queue_redraw()
func check(coord: Vector2i):
	if walkable.has(coord):
		return
	walkable[coord] = TileStatus.FREE if _is_clear(coord, static_layer_mask) else TileStatus.NEVER
	if walkable[coord]:
		_add_frontier(coord+Vector2i(-1, 0))
		_add_frontier(coord+Vector2i(1, 0))
		_add_frontier(coord+Vector2i(0, -1))
		_add_frontier(coord+Vector2i(0, 1))
	queue_redraw()

func _rebuild_internals():
	finder.cell_size = Vector2(alignment.tile_set.tile_size.x, alignment.tile_set.tile_size.y)
	finder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	finder.region = region
	finder.update()
	finder.fill_solid_region(region, true)
	dynamic_cache = walkable.keys()
	dynamic_index = 0
	for w in walkable.keys():
		if walkable[w] == TileStatus.FREE:
			finder.set_point_solid(w, false)

func _world_position_to_tile_position(p: Vector2) -> Vector2i:
	var d = alignment.to_local(p)
	d.x /= alignment.tile_set.tile_size.x
	d.y /= alignment.tile_set.tile_size.y
	if d.x < 0.0:
		d.x -= 1
	if d.y < 0.0:
		d.y -= 1
	return Vector2i(int(d.x), int(d.y))

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	finder = AStarGrid2D.new()
	shape_rid = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape_rid, agent_radius)

	for c in get_children():
		if c is Node2D:
			_add_frontier(_world_position_to_tile_position(c.global_position))
	
	current = frontier.pop_back()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or alignment == null:
		return
	## For some reason, we need to do this
	## to avoid false holes.
	if fix_flip:
		fix_flip = false
		return
	if running:
		for _i in range(static_checks_per_frame):
			if !running:
				break
			while walkable.has(current):
				if len(frontier) == 0:
					running = false
					_rebuild_internals()
					break
				current = frontier.pop_back()
			check(current)
	else:
		var cache_len: int = len(dynamic_cache)
		for _i in range(dynamic_checks_per_frame):
			_dynamic_check(dynamic_cache[dynamic_index])
			dynamic_index = wrapi(dynamic_index+1, 0, cache_len)

func _draw() -> void:
	if alignment == null or !visible: return
	var size = alignment.tile_set.tile_size
	var rp = to_local(alignment.global_position + alignment.to_global(Vector2(region.position.x*size.x, region.position.y*size.y)))
	var r = Rect2(rp.x, rp.y, region.size.x*size.x, region.size.y*size.y)
	draw_rect(r, Color.WHITE, false, 3.0)
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
	for k in walkable.keys():
		var col = Color(1.0, 1.0, 1.0, 0.8)
		var pos = to_local(alignment.global_position + alignment.to_global(Vector2(k.x*size.x, k.y*size.y)))
		if walkable[k] == TileStatus.NEVER:
			col = Color(1.0, 0.3, 0.3, 1.0)
		if walkable[k] == TileStatus.OCCUPIED:
			col = Color(1.0, 1.0, 0.2, 1.0)
		draw_circle(pos+(size*0.5), agent_radius, col)

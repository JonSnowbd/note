@tool
extends Node2D
class_name SimpleParallax2D

const MetaTag = "__note_simple_parallax_meta_id"

## A slightly

@export var view_control: Node2D
@export var anchor_position: Vector2
@export var cam_offset: Vector2
@export var parallax: float = 0.0
@export_group("Texturing")
@export_tool_button("Force Refresh") var _refresh = _update_bits
@export var visual_node: Node2D : 
	set(val):
		if val != visual_node:
			visual_node = val
			_update_bits()
@export var visual_node_size: Vector2 : 
	set(val):
		if val != visual_node_size:
			visual_node_size = val
			_update_bits_positions()
@export var repeats: Vector2i = Vector2i.ZERO : 
	set(val):
		if val != repeats:
			repeats = val
			_update_bits()

var extra_bits: Array[Node2D] = []

func _ready() -> void:
	_update_bits()

func _process(delta: float) -> void:
	if visible and view_control != null:
		var local_offset = to_local(view_control.global_position)
		position = anchor_position + ((local_offset+cam_offset) * parallax)


func dupe_visual() -> Node2D:
	return visual_node.duplicate()

func _update_bits_positions():
	var sz = visual_node_size
	for x in extra_bits:
		var vec: Vector2i = x.get_meta(MetaTag)
		x.position = Vector2(vec.x*sz.x, vec.y*sz.y)
func _update_bits():
	var sz = visual_node_size
	for x in extra_bits:
		x.queue_free()
	extra_bits.clear()
	if visual_node == null or visual_node_size == Vector2.ZERO:
		return
	for y in range(-repeats.y, repeats.y+1):
		for x in range(-repeats.x, repeats.x+1):
			if x == 0 and y == 0: continue # Skip middle bit, the visual node IS the center bit.
			var duped_piece = dupe_visual()
			var vec = Vector2i(x, y)
			duped_piece.set_meta(MetaTag, vec)
			extra_bits.append(duped_piece)
			add_child(duped_piece)
			duped_piece.position = visual_node.position + Vector2(x*sz.x, y*sz.y)

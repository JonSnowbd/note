@tool
extends Marker3D
class_name Forwarder3Dto2D

@export var target_node: CanvasItem
@export var on_physics: bool = false

func _work():
	if target_node == null: return
	var cam = get_viewport().get_camera_3d()
	var world_space = cam.unproject_position(global_position)
	if target_node is Control:
		target_node.position = target_node.make_canvas_position_local(world_space)
	elif target_node is Node2D:
		target_node.global_position = world_space

func _process(delta: float) -> void:
	if !on_physics:
		_work()
func _physics_process(delta: float) -> void:
	if on_physics:
		_work()

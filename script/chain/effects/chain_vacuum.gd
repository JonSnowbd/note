extends ChainNode
class_name ChainFXVacuum

## If the context of the chain is a node2D of some kind, this will suck it up.
## Useful for zone transitions, or entering vehicles.

## Needed, assign this and the context will be sucked into the center of this node
@export var vacuum_destination: Node
@export_group("Tuning")
@export var vacuum_speed: float = 9.5
@export var snap_distance: float = 0.05
@export var snap_after_threshold: bool = true

func _chain_start(instance: RunInstance):
	pass
func _chain_work(instance: RunInstance, delta: float) -> Response:
	# 2D
	if vacuum_destination is Node2D and instance.context is Node2D:
		var n = instance.context as Node2D
		n.global_position = note.util.smooth_toward_v2(n.global_position, vacuum_destination.global_position, vacuum_speed, delta)
		if n.global_position.distance_to(vacuum_destination.global_position) < snap_distance:
			if snap_after_threshold:
				n.global_position = vacuum_destination.global_position
			return Response.DONE
		return Response.WORKING
	
	# 3D
	if vacuum_destination is Node3D and instance.context is Node3D:
		var n = instance.context as Node3D
		n.global_position = note.util.smooth_toward_v3(n.global_position, vacuum_destination.global_position, vacuum_speed, delta)
		if n.global_position.distance_to(vacuum_destination.global_position) < snap_distance:
			if snap_after_threshold:
				n.global_position = vacuum_destination.global_position
			return Response.DONE
		return Response.WORKING
	
	# If neither type match, just end the chain node.
	return Response.DONE

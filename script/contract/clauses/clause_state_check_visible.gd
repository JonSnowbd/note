extends Contract.Clause
class_name ClauseCheckVisible

## Checks if 2 objects are within range of eachother.

var target: Node

func _init(first_object) -> void:
	target = first_object
func is_still_valid() -> bool:
	if target == null or (target.is_queued_for_deletion() or !is_instance_valid(target)):
		return false
	if target is Node3D:
		return target.visible
	if target is CanvasItem:
		return target.visible
	return false

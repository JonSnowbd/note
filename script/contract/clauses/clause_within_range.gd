extends Contract.Clause
class_name ClauseWithinRange

## Checks if 2 objects are within range of eachother.

var first
var second
var range: float

func _init(first_object, second_object, distance: float) -> void:
	first = first_object
	second = second_object
	range = distance
func is_still_valid() -> bool:
	if first is Node3D and second is Node3D:
		return first.global_position.distance_to(second.global_position) <= range
	if first is Node2D and second is Node2D:
		return first.global_position.distance_to(second.global_position) <= range
	return false

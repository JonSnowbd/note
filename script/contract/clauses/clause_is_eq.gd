extends Contract.Clause
class_name ClauseIsEq

## Checks if 2 objects are within range of eachother.

var object: Object
var member_name: StringName
var expectation

func _init(obj: Object, var_name: StringName, expected_value) -> void:
	object = obj
	member_name
func is_still_valid() -> bool:
	if expectation is float:
		return is_equal_approx(object.get(member_name), expectation)
	else:
		return object.get(member_name) == expectation

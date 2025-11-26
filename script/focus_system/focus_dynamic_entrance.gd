extends Node
class_name FocusDynamicEntrance

const MetaTag = "__NOTE_FOCUS_DYNAMIC_ENTRANCE_METATAG"

@export var excludes: Array[Control]

func _enter_tree() -> void:
	get_parent().set_meta(MetaTag, self)
func _exit_tree() -> void:
	get_parent().remove_meta(MetaTag)


func get_new_target(from_local: Vector2, impulse: Vector2) -> Control:
	var parent = get_parent()
	if parent.get_child_count() <= 1:
		return null
	var intended_position =  from_local+(impulse*2.0)
	var closest_child: Control = null
	var closest_child_dist = INF
	for c in parent.get_children():
		if c is Control:
			if excludes.has(c):
				continue
			var distance = c.position.distance_to(intended_position)
			if distance <= closest_child_dist:
				closest_child = c
				closest_child_dist = distance
	return closest_child

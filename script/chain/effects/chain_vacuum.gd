extends ChainFX
class_name ChainVacuum

## If the context of the chain is a node2D of some kind, this will suck it up.
## Useful for zone transitions, or entering vehicles.

## Needed, assign this and the context will be sucked into the center of this node
@export var suction_center_node: Node2D

@export_subgroup("Motion", "motion_")
## Set to 0.0 to disable the motion part of the vacuum effect.
@export var motion_duration: float = 0.0
## The transition function used for the tween
@export var motion_transition_type: Tween.TransitionType
## Which parts of the ease the function is used on, in the tween.
@export var motion_transition_ease: Tween.EaseType

var tween: Tween


func _start(data):
	tween = create_tween()
	tween.set_parallel(true)
	
	var dest = suction_center_node.global_position
	tween.tween_property(data, "global_position", dest, motion_duration*time_scale)\
	.set_ease(motion_transition_ease)\
	.set_trans(motion_transition_type)
	
	tween.tween_callback(on_finish.emit)
	
	on_start.emit()

func _done() -> bool:
	if tween == null:
		return true
	return !tween.is_running()

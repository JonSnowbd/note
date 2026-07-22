extends ChainNode
class_name ChainFXTweenValue

## A simple quick tween. Operates on one value, multiple Chain Tween nodes will
## each be their own tween. Recommended if the destination value is known ahead of time.

@export_category("Tween Target")
## The path to the member that will be tweened, such as [code]position:x[/code] or
## [code]modulate[/code]. To target shader parameters use [code]!!uniform_name[/code] the !! at
## the start to denote that we are going to change a shader param, and use i! to target instance parameter.
@export var value_name: String
## What the above value will be changed to over time
@export var value_target: Variant
## If set, this node will override the chain node target
@export var context_override: Node

@export_group("Tuning")
@export var tween_duration: float = 1.0
@export var tween_interp: Tween.EaseType
@export var tween_tempo: Tween.TransitionType
## If true, the tween will be instantly completed when the chain node is cancelled
## instead of just stopping.
@export var fast_forward_on_cancel: bool = true

func _chain_start(instance: RunInstance):
	var target = instance.context
	if context_override != null:
		target = context_override
	
	# Use note tween, to auto-end if it repeats.
	var t = note.util.tween(target, "__chain_tween_%s" % name) 
	t.set_ease(tween_interp)
	t.set_trans(tween_tempo)
	
	# Get shader if possible
	var shader: ShaderMaterial
	if target is CanvasItem:
		shader = target.material as ShaderMaterial
	elif target is GeometryInstance3D:
		if target.material_override != null:
			shader = target.material_override as ShaderMaterial
	
	
	if value_name.begins_with("!!"):
		if shader == null: 
			note.warn("%s: failed to tween shader material uniform, as material is of the incorrect type")
			return
		var new_value_name = value_name.substr(2)
		var from = shader.get_shader_parameter(new_value_name)
		var lambda = func(value):
			shader.set_shader_parameter(new_value_name, value)
		t.tween_method(lambda, from, value_target, tween_duration)
	elif value_name.begins_with("i!"):
		if shader == null: 
			note.warn("%s: failed to tween shader material instance uniform, as material is of the incorrect type")
			return
		var new_value_name = value_name.substr(2)
		var from = target.get_instance_shader_parameter(new_value_name)
		var lambda = func(value):
			target.set_instance_shader_parameter(new_value_name, value)
		t.tween_method(lambda, from, value_target, tween_duration)
	else:
		t.tween_property(target, value_name, value_target, tween_duration)
	instance.data.set(&"awaiting_tween", t)
func _chain_cancel(instance: RunInstance):
	var tween: Tween = instance.data.get(&"awaiting_tween")
	if tween != null:
		if tween.is_running():
			if fast_forward_on_cancel:
				tween.pause()
				while tween.custom_step(2.0): pass
			else:
				tween.stop()
func _chain_work(instance: RunInstance, delta: float) -> Response:
	var tween: Tween = instance.data.get(&"awaiting_tween")
	if tween != null and tween.is_running():
		return Response.WORKING
	
	return Response.DONE

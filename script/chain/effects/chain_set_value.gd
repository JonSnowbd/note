extends ChainNode
class_name ChainFXSetValue

## A simple chain effect that sets multiple values on the context. This is an
## instant effect. On start, is_instant will be set to true.

@export var value_set_list: Dictionary[StringName,Variant] = {}
## If set, this node will override the chain node target
@export var context_override: Node

func _chain_start(instance: RunInstance):
	is_instant = true
	if instance.context != null:
		for k in value_set_list.keys():
			instance.context.set(k, value_set_list[k])

func _chain_work(instance: RunInstance, delta: float) -> Response:
	return Response.DONE

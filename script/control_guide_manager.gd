extends Container
class_name ControlGuideManager

@export var input_icon_theme: InputTextureMap
@export var guidelet_prefab: PackedScene
@export var container: Container


func clear_controls():
	for c in container.get_children():
		c.queue_free()
func make_auto(action: StringName, label: String, include_gamepad: bool = true, include_kbm: bool = true) -> ControlGuidelet:
	var guidelet: ControlGuidelet = guidelet_prefab.instantiate()
	guidelet.set_action_name(label)
	guidelet.add_icons_of_action(action, input_icon_theme, include_gamepad, include_kbm)
	container.add_child(guidelet)
	return guidelet
func make_manual(label: String) -> ControlGuidelet:
	var guidelet: ControlGuidelet = guidelet_prefab.instantiate()
	guidelet.set_action_name(label)
	container.add_child(guidelet)
	return guidelet

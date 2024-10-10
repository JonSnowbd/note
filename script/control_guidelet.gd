extends Control
class_name ControlGuidelet

@export var icon_container: Container
@export var label: Label

@export_category("Icon Settings")
@export var icon_size: float = 32.0

func _wasd_check(actions: Array[InputEvent]) -> bool:
	return false

func clear_icons():
	for c in icon_container.get_children():
		if c is TextureRect:
			c.queue_free()
func add_icon_manual(icon: Texture):
	var new_icon := TextureRect.new()
	new_icon.texture = icon
	new_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	new_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	new_icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon_container.add_child(new_icon)
func add_icons_of_action(action: String, icon_theme: InputTextureMap, include_gamepad: bool = true, include_kbm: bool = true):
	var actions = InputMap.action_get_events(action)
	for a in actions:
		if a is InputEventKey and include_kbm:
			add_icon_manual(icon_theme.key_to_texture(a.physical_keycode))
		if a is InputEventMouseButton and include_kbm:
			add_icon_manual(icon_theme.mouse_button_to_texture(a.button_index))
		if a is InputEventJoypadButton and include_gamepad:
			add_icon_manual(icon_theme.xbox_button_to_texture(a.button_index))
		if a is InputEventJoypadMotion and include_gamepad:
			add_icon_manual(icon_theme.xbox_axis_to_texture(a.axis))
func set_action_name(name: String):
	if label != null:
		label.text = name

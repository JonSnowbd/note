extends Container
class_name PopupManager

@export var root: Container
@export var popup_prefab: PackedScene

## coordinates are given in 0-1 where they lay on the screen: eg 0.0,0.5 will give you left centered
## popups.
func set_screen_position(x: float, y: float):
	anchor_left = x
	anchor_right = x
	anchor_top = y
	anchor_bottom = y
## Sets padding on the popup container, useful for maintaining a constant offset
## from an edge, rather than a proportion.
func set_padding(left_px: float, right_px: float, top_px: float, bottom_px: float, h_direction: Control.GrowDirection = Control.GROW_DIRECTION_BOTH, v_direction: Control.GrowDirection = Control.GROW_DIRECTION_BOTH):
	add_theme_constant_override("margin_left", left_px)
	add_theme_constant_override("margin_right", right_px)
	add_theme_constant_override("margin_top", top_px)
	add_theme_constant_override("margin_bottom", bottom_px)
	grow_horizontal = h_direction
	grow_vertical = v_direction

## Returns an empty message, for complete customization.
func empty(duration: float = 2.0) -> PopupMessage:
	var msg = popup_prefab.instantiate() as PopupMessage
	msg.default_content.hide()
	msg.lifespan = duration
	root.add_child(msg)
	return msg
## Simple rich text enabled message popup.
func send(message: String, duration: float = 2.0) -> PopupMessage:
	var msg = popup_prefab.instantiate() as PopupMessage
	msg.default_content.text = message
	msg.lifespan = duration
	root.add_child(msg)
	return msg
## Makes a popup message, and passes data along to the instanced content via a method `popup(your_data)`
func send_advanced(content: PackedScene, data = null, duration: float = 2.0) -> PopupMessage:
	var msg = popup_prefab.instantiate() as PopupMessage
	msg.default_content.hide()
	msg.lifespan = duration
	var new_content = content.instantiate()
	if new_content.has_method("popup"):
		new_content.popup(data)
	msg.content_root.add_child(new_content)
	root.add_child(msg)
	return msg

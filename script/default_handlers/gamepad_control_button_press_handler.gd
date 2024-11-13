extends NoteGamepadControlHandler
class_name NoteGamepadControlHandlerButtonPress

@export var on_primary: bool
@export var on_secondary: bool

func handler_input(context: NoteGamepadControlManager, event: InputEvent) -> bool:
	for confirm in context.confirm_action:
		if on_primary and event.is_action_pressed(confirm):
			var btn = get_parent() as Button
			btn.button_pressed = true
			btn.emit_signal("pressed")
			return true
	for cancel in context.cancel_action:
		if on_secondary and event.is_action_pressed(cancel):
			var btn = get_parent() as Button
			btn.button_pressed = true
			btn.emit_signal("pressed")
			return true
	return false

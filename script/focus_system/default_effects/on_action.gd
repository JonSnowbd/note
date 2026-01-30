extends FocusEffect
class_name OnActionFocusEffect

## A general action effect, use the signals to react to focus inputs.

signal on_confirm
signal on_confirm_long_press
signal on_cancel
signal on_cancel_long_press
signal on_special1
signal on_special1_long_press
signal on_special2
signal on_special2_long_press
signal on_butted(direction: Vector2)


@export var enable_long_press_behaviour: bool = false
var awaiting_consume: bool = true

func _ready() -> void:
	has_long_press = enable_long_press_behaviour

## Call this in your signal response to have the action
## consume the input before the other focus effects get a chance.
func consume_input():
	awaiting_consume = false

func focus_butted(impulse: Vector2) -> bool:
	on_butted.emit(impulse)
	return on_butted.has_connections()
func focus_confirm(down: bool, long: bool = false) -> bool:
	awaiting_consume = true
	if down:
		if long:
			on_confirm_long_press.emit()
		else:
			on_confirm.emit()
	return !awaiting_consume
func focus_cancel(down: bool, long: bool = false) -> bool:
	awaiting_consume = true
	if down:
		if long:
			on_cancel_long_press.emit()
		else:
			on_cancel.emit()
	return !awaiting_consume
func focus_special1(down: bool, long: bool = false) -> bool:
	awaiting_consume = true
	if down:
		if long:
			on_special1_long_press.emit()
		else:
			on_special1.emit()
	return !awaiting_consume
func focus_special2(down: bool, long: bool = false) -> bool:
	awaiting_consume = true
	if down:
		if long:
			on_special2_long_press.emit()
		else:
			on_special2.emit()
	return !awaiting_consume

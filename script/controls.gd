extends Node

## A selection of input methods that can be changed
## on the fly.
enum Type {
	Mobile,
	Gamepad,
	MouseKeyboard
}

## Called when input is changed from 
signal input_method_changed(new_mode: Type)
signal is_now_keyboard
signal is_now_gamepad

var current_mode: Type = Type.MouseKeyboard

var __mouse_track: float = 0.0
@onready var _nt = get_tree().root.get_node("note")

func _ready() -> void:
	pass

## Note features a robust gamepad ui control scheme. If you disable
## note's automatic controller detection, this is how you toggle it.
## Not needed if you are letting note automatically detect changes.
func set_mode(new_mode: Type):
	if new_mode == Type.MouseKeyboard:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if new_mode != current_mode:
		current_mode = new_mode
		input_method_changed.emit(new_mode)
		match new_mode:
			Type.MouseKeyboard:
				is_now_keyboard.emit()
				_nt.info("Changed input mode to Mouse & Keyboard")
			Type.Gamepad:
				is_now_gamepad.emit()
				_nt.info("Changed input mode to Gamepad")
			Type.Mobile:
				_nt.info("Changed input mode to Mobile Input")
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		__mouse_track += event.relative.length()
		if __mouse_track > 100.0:
			__mouse_track = 0.0
			set_mode(Type.MouseKeyboard)
	if event is InputEventKey or event is InputEventMouseButton:
		set_mode(Type.MouseKeyboard)
	if event is InputEventJoypadButton:
		set_mode(Type.Gamepad)
	if event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.4:
			set_mode(Type.Gamepad)

func is_mouse_and_keyboard() -> bool: return current_mode == Type.MouseKeyboard
func is_gamepad() -> bool: return current_mode == Type.Gamepad
func is_mobile() -> bool: return current_mode == Type.Mobile

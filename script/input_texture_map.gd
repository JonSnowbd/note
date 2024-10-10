extends Resource
class_name InputTextureMap

@export_category("Keyboard")
@export var key_1: Texture
@export var key_2: Texture
@export var key_3: Texture
@export var key_4: Texture
@export var key_5: Texture
@export var key_6: Texture
@export var key_7: Texture
@export var key_8: Texture
@export var key_9: Texture
@export var key_0: Texture
@export var key_dash: Texture
@export var key_equals: Texture
@export var key_q: Texture
@export var key_w: Texture
@export var key_e: Texture
@export var key_r: Texture
@export var key_t: Texture
@export var key_y: Texture
@export var key_u: Texture
@export var key_i: Texture
@export var key_o: Texture
@export var key_p: Texture
@export var key_a: Texture
@export var key_s: Texture
@export var key_d: Texture
@export var key_f: Texture
@export var key_g: Texture
@export var key_h: Texture
@export var key_j: Texture
@export var key_k: Texture
@export var key_l: Texture
@export var key_z: Texture
@export var key_x: Texture
@export var key_c: Texture
@export var key_v: Texture
@export var key_b: Texture
@export var key_n: Texture
@export var key_m: Texture
@export var key_tilde: Texture
@export var key_bkspc: Texture
@export var key_space: Texture
@export var key_tab: Texture
@export var key_enter: Texture
@export var key_lshift: Texture
@export var key_rshift: Texture
@export var key_lctrl: Texture
@export var key_rctrl: Texture
@export var key_lalt: Texture
@export var key_ralt: Texture
@export var key_lsuper: Texture
@export var key_rsuper: Texture
@export var key_backslash: Texture
@export var key_forwardslash: Texture
@export var key_open_square_bracket: Texture
@export var key_close_square_bracket: Texture
@export var key_capslock: Texture
@export var key_escape: Texture
@export var key_f1: Texture
@export var key_f2: Texture
@export var key_f3: Texture
@export var key_f4: Texture
@export var key_f5: Texture
@export var key_f6: Texture
@export var key_f7: Texture
@export var key_f8: Texture
@export var key_f9: Texture
@export var key_f10: Texture
@export var key_f11: Texture
@export var key_f12: Texture
@export var key_f13: Texture
@export var key_f14: Texture
@export var key_f15: Texture
@export var key_f16: Texture
@export var key_f17: Texture
@export var key_f18: Texture
@export var key_f19: Texture
@export var key_f20: Texture
@export var key_f21: Texture
@export var key_f22: Texture
@export var key_up_arrow: Texture
@export var key_right_arrow: Texture
@export var key_down_arrow: Texture
@export var key_left_arrow: Texture
@export var key_ins: Texture
@export var key_home: Texture
@export var key_pgup: Texture
@export var key_pgdn: Texture
@export var key_del: Texture
@export var key_end: Texture
@export var key_apostraphe: Texture
@export var key_colon: Texture
@export var key_comma: Texture
@export var key_period: Texture
@export var key_question_mark: Texture
@export var key_print_screen: Texture
@export var key_h_wasd: Texture
@export var key_v_wasd: Texture
@export var key_l_wasd: Texture
@export var key_r_wasd: Texture
@export var key_u_wasd: Texture
@export var key_d_wasd: Texture
@export var key_wasd: Texture
@export var key_all_wasd: Texture
@export var key_any: Texture

@export_category("Mouse")
@export var mouse_h: Texture
@export var mouse_v: Texture
@export var mouse: Texture
@export var mouse_wheel: Texture
@export var mouse_wheel_up: Texture
@export var mouse_wheel_down: Texture
@export var mouse_left_click: Texture
@export var mouse_right_click: Texture


@export_category("Xbox")
@export var xbox_lstick: Texture
@export var xbox_h_lstick: Texture
@export var xbox_v_lstick: Texture
@export var xbox_l_lstick: Texture
@export var xbox_r_lstick: Texture
@export var xbox_u_lstick: Texture
@export var xbox_d_lstick: Texture
@export var xbox_l3: Texture

@export var xbox_rstick: Texture
@export var xbox_h_rstick: Texture
@export var xbox_v_rstick: Texture
@export var xbox_l_rstick: Texture
@export var xbox_r_rstick: Texture
@export var xbox_u_rstick: Texture
@export var xbox_d_rstick: Texture
@export var xbox_r3: Texture

@export var xbox_h_dpad: Texture
@export var xbox_v_dpad: Texture
@export var xbox_l_dpad: Texture
@export var xbox_r_dpad: Texture
@export var xbox_u_dpad: Texture
@export var xbox_d_dpad: Texture
@export var xbox_all_dpad: Texture
@export var xbox_dpad: Texture

@export var xbox_a: Texture
@export var xbox_b: Texture
@export var xbox_x: Texture
@export var xbox_y: Texture

@export var xbox_lb: Texture
@export var xbox_rb: Texture
@export var xbox_lt: Texture
@export var xbox_rt: Texture
@export var xbox_back: Texture
@export var xbox_start: Texture
@export var xbox_guide: Texture

func xbox_axis_to_texture(axis: JoyAxis) -> Texture:
	match(axis):
		JOY_AXIS_LEFT_X: return xbox_h_lstick
		JOY_AXIS_LEFT_Y: return xbox_v_lstick
		JOY_AXIS_RIGHT_X: return xbox_h_rstick
		JOY_AXIS_RIGHT_Y: return xbox_v_rstick
		JOY_AXIS_TRIGGER_LEFT: return xbox_lt
		JOY_AXIS_TRIGGER_RIGHT: return xbox_rt
	return key_any
func xbox_button_to_texture(button: JoyButton) -> Texture:
	match button:
		JOY_BUTTON_A: return xbox_a
		JOY_BUTTON_B: return xbox_b
		JOY_BUTTON_X: return xbox_x
		JOY_BUTTON_Y: return xbox_y
		JOY_BUTTON_BACK: return xbox_back
		JOY_BUTTON_START: return xbox_start
		JOY_BUTTON_LEFT_STICK: return xbox_l3
		JOY_BUTTON_RIGHT_STICK: return xbox_r3
		JOY_BUTTON_LEFT_SHOULDER: return xbox_lb
		JOY_BUTTON_RIGHT_SHOULDER: return xbox_rb
		JOY_BUTTON_DPAD_UP: return xbox_u_dpad
		JOY_BUTTON_DPAD_DOWN: return xbox_d_dpad
		JOY_BUTTON_DPAD_LEFT: return xbox_l_dpad
		JOY_BUTTON_DPAD_RIGHT: return xbox_r_dpad
	return key_any
func mouse_button_to_texture(button: MouseButton) -> Texture:
	match button:
		MOUSE_BUTTON_LEFT: return mouse_left_click
		MOUSE_BUTTON_RIGHT: return mouse_right_click
		MOUSE_BUTTON_MIDDLE: return mouse_wheel
		MOUSE_BUTTON_WHEEL_UP: return mouse_wheel_up
		MOUSE_BUTTON_WHEEL_DOWN: return mouse_wheel_down
	return key_any
func key_to_texture(key: Key) -> Texture:
	match key:
		KEY_1: return key_1
		KEY_2: return key_2
		KEY_3: return key_3
		KEY_4: return key_4
		KEY_5: return key_5
		KEY_6: return key_6
		KEY_7: return key_7
		KEY_8: return key_8
		KEY_9: return key_9
		KEY_0: return key_0
		KEY_MINUS: return key_dash
		KEY_EQUAL: return key_equals
		KEY_Q: return key_q
		KEY_W: return key_w
		KEY_E: return key_e
		KEY_R: return key_r
		KEY_T: return key_t
		KEY_Y: return key_y
		KEY_U: return key_u
		KEY_I: return key_i
		KEY_O: return key_o
		KEY_P: return key_p
		KEY_A: return key_a
		KEY_S: return key_s
		KEY_D: return key_d
		KEY_F: return key_f
		KEY_G: return key_g
		KEY_H: return key_h
		KEY_J: return key_j
		KEY_K: return key_k
		KEY_L: return key_l
		KEY_Z: return key_z
		KEY_X: return key_x
		KEY_C: return key_c
		KEY_V: return key_v
		KEY_B: return key_b
		KEY_N: return key_n
		KEY_M: return key_m
		KEY_ASCIITILDE: return key_tilde
		KEY_BACKSPACE: return key_bkspc
		KEY_SPACE: return key_space
		KEY_TAB: return key_tab
		KEY_ENTER: return key_enter
		KEY_SHIFT: return key_lshift
		KEY_SHIFT: return key_rshift
		KEY_CTRL: return key_lctrl
		KEY_CTRL: return key_rctrl
		KEY_ALT: return key_lalt
		KEY_ALT: return key_ralt
		KEY_META: return key_lsuper
		KEY_META: return key_rsuper
		KEY_BACKSLASH: return key_backslash
		KEY_SLASH: return key_forwardslash
		KEY_BRACKETLEFT: return key_open_square_bracket
		KEY_BRACKETRIGHT: return key_close_square_bracket
		KEY_CAPSLOCK: return key_capslock
		KEY_ESCAPE: return key_escape
		KEY_F1: return key_f1
		KEY_F2: return key_f2
		KEY_F3: return key_f3
		KEY_F4: return key_f4
		KEY_F5: return key_f5
		KEY_F6: return key_f6
		KEY_F7: return key_f7
		KEY_F8: return key_f8
		KEY_F9: return key_f9
		KEY_F10: return key_f10
		KEY_F11: return key_f11
		KEY_F12: return key_f12
		KEY_F13: return key_f13
		KEY_F14: return key_f14
		KEY_F15: return key_f15
		KEY_F16: return key_f16
		KEY_F17: return key_f17
		KEY_F18: return key_f18
		KEY_F19: return key_f19
		KEY_F20: return key_f20
		KEY_F21: return key_f21
		KEY_F22: return key_f22
		KEY_UP: return key_up_arrow
		KEY_RIGHT: return key_right_arrow
		KEY_DOWN: return key_down_arrow
		KEY_LEFT: return key_left_arrow
		KEY_INSERT: return key_ins
		KEY_HOME: return key_home
		KEY_PAGEUP: return key_pgup
		KEY_PAGEDOWN: return key_pgdn
		KEY_DELETE: return key_del
		KEY_END: return key_end
		KEY_APOSTROPHE: return key_apostraphe
		KEY_COLON: return key_colon
		KEY_COMMA: return key_comma
		KEY_PERIOD: return key_period
		KEY_QUESTION: return key_question_mark
		KEY_PRINT: return key_print_screen
	
	return key_any

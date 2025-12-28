extends Button

@export var icon_when_kb: Texture2D
@export var icon_when_gp: Texture2D
@export var icon_when_mobile: Texture2D


@onready var _nt = get_tree().root.get_node("note")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_nt.controls.input_method_changed.connect(update)
	update(_nt.controls.current_mode)

func update(to_type):
	match to_type:
		_nt.TypeControlManager.Type.Mobile:
			icon = icon_when_mobile
		_nt.TypeControlManager.Type.Gamepad:
			icon = icon_when_gp
		_nt.TypeControlManager.Type.MouseKeyboard:
			icon = icon_when_kb

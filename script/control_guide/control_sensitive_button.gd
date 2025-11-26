extends Button

@export var icon_when_kb: Texture2D
@export var icon_when_gp: Texture2D
@export var icon_when_mobile: Texture2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	note.controls.input_method_changed.connect(update)
	update(note.controls.current_mode)

func update(to_type: note.TypeControlManager.Type):
	match to_type:
		note.TypeControlManager.Type.Mobile:
			icon = icon_when_mobile
		note.TypeControlManager.Type.Gamepad:
			icon = icon_when_gp
		note.TypeControlManager.Type.MouseKeyboard:
			icon = icon_when_kb

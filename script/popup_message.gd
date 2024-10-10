extends Control
class_name PopupMessage

@export var content_root: Container
@export var default_content: RichTextLabel

var time: float = 0.0
var lifespan: float = 2.0
var dismissing: bool = false
var target_alpha: float = 1.0

func dismiss():
	dismissing = true
	target_alpha = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var dt = note.util.unscaled_dt()
	time += dt
	if !dismissing and time >= lifespan:
		dismiss()
	if dismissing:
		modulate.a = move_toward(modulate.a, target_alpha, dt * 3.0)
	if modulate.a == 0.0:
		queue_free()

func _gui_input(event: InputEvent) -> void:
	if !dismissing and event is InputEventMouseButton:
		if event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			get_viewport().set_input_as_handled()
			dismiss()

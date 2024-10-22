extends NoteGamepadControlEffect
class_name NoteGamepadControlEffectIcon

@export var origin: Vector2 = Vector2(0.0, 0.5)
@export var icon: Texture2D
@export var size: Vector2 = Vector2(16.0, 16.0)
@export var color: Color = Color.WHITE


## Virtual, if you need to draw each frame, this is done
## centered on the control.
func effect_draw(source: Node2D, context: Control):
	if icon != null:
		source.draw_set_transform((context.size*origin)+(size*-0.5), 0.0, size/icon.get_size())
		source.draw_texture(icon, Vector2.ZERO, color)
		source.draw_set_transform(Vector2.ZERO)

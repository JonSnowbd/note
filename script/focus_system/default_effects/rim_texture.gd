extends FocusEffect
class_name RimTextureFocusEffect

## Draws a texture on the control when the focus is over the control.
## This can be set to draw while inside the control aswell.

@export var icon: Texture2D
@export var size: Vector2 = Vector2(16.0, 16.0)
@export var tint: Color = Color.WHITE
## If true the drawing is placed on the control this belongs to, rather
## than the focus box.
@export var attached_to_control: bool = true
## If true, this will be drawn while the focus is hovering any control
## inside this control, or while selected itself.
@export var while_focus_in_children: bool = false
@export_group("Origins")
@export var icon_origin: Vector2 = Vector2(0.5, 0.5)
@export var destination_origin: Vector2 = Vector2(1.0, 0.5)


func focus_acknowledge():
	if while_focus_in_children:
		move_to_stack()
func focus_draw(source: Control):
	if while_focus_in_children and manager.target != get_parent():
		if !get_parent().is_ancestor_of(manager.target):
			return
	var destination = Rect2()
	if attached_to_control:
		destination = manager.get_local_rect(get_parent())
	else:
		destination = Rect2(Vector2.ZERO, manager.size)
	
	var stamp = destination.position+(destination.size*destination_origin)-(size*icon_origin)
	source.draw_texture_rect(icon, Rect2(stamp, size), false, tint)

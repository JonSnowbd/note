@tool
extends Control

signal piece_request(at: int, new_script: String)

@export var container: BoxContainer

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		show()
	if what == NOTIFICATION_DRAG_END:
		hide()

func _get_index() -> int:
	var index = 0
	for child in container.get_children():
		if child is Control:
			var cmp = child.get_local_mouse_position()
			if cmp.y > child.size.y*0.5:
				index += 1
	return index
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	queue_redraw()
	return data is String

func _drop_data(at_position: Vector2, data: Variant) -> void:
	piece_request.emit(_get_index(), data as String)

func _draw() -> void:
	if container == null: return
	if container.get_child_count() == 0:
		draw_line(container.global_position, container.global_position+container.size*Vector2(1.0, 0.0), Color.YELLOW, 2)
		return
	var mp = get_local_mouse_position()
	var index = _get_index()
	if index >= container.get_child_count():
		draw_line(container.global_position+container.size*Vector2(0.0, 1.0), container.global_position+container.size, Color.YELLOW, 2)
	else:
		var child_at = container.get_child(index) as Control
		draw_line(child_at.global_position, child_at.global_position+child_at.size*Vector2(1.0, 0.0), Color.YELLOW, 2)

@tool
extends Control

signal piece_request(at: int, new_script: String)
signal piece_move(to: int, piece: NoteJournalResource.Piece)

@export var container: BoxContainer

func _notification(what: int) -> void:
	if is_part_of_edited_scene(): return
	if what == NOTIFICATION_DRAG_BEGIN:
		var data = get_viewport().gui_get_drag_data()
		if _is_valid_type(data):
			show()
	if what == NOTIFICATION_DRAG_END:
		hide()
func _is_valid_drop() -> bool:
	var distance_from_center = abs((container.size.x*0.5) - container.get_local_mouse_position().x)
	return distance_from_center < 200.0
func _is_valid_type(data) -> bool:
	#return data is String or data is NoteJournalResource.Piece
	return data is String
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
	if !_is_valid_type(data):
		hide()
	return _is_valid_drop() and _is_valid_type(data)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data is String:
		piece_request.emit(_get_index(), data as String)
	if data is NoteJournalResource.Piece:
		piece_move.emit(_get_index(), data as NoteJournalResource.Piece)

func _ready() -> void:
	hide()
func _draw() -> void:
	if is_part_of_edited_scene(): return
	if container == null: return
	if !_is_valid_drop():
		return
	if container.get_child_count() == 0:
		draw_line(container.global_position, container.global_position+container.size*Vector2(1.0, 0.0), Color.YELLOW, 2)
		return
	var index = _get_index()
	if index >= container.get_child_count():
		var pos = make_canvas_position_local(container.global_position)
		draw_line(pos+container.size*Vector2(0.0, 1.0), pos+container.size, Color.YELLOW, 2)
	else:
		var child_at = container.get_child(index) as Control
		var pos = make_canvas_position_local(child_at.global_position)
		draw_line(pos, pos+child_at.size*Vector2(1.0, 0.0), Color.YELLOW, 2)

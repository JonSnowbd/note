@tool
extends Control

@export var target: Control

var tween: Tween
var trip: bool = false
var stop_listening: bool = false
func _ready() -> void:
	if is_part_of_edited_scene(): return
	if target == null:
		return
	offset_transform_position.x = target.size.x+20.0

func open():
	if target == null:
		return
	if tween != null:
		tween.stop()
	tween = create_tween()
	tween.tween_property(self, "offset_transform_position:x", 0.0, 0.25)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		trip = true
	)
func close():
	if target == null:
		return
	if tween != null:
		tween.stop()
	tween = create_tween()
	tween.tween_property(self, "offset_transform_position:x", target.size.x + 20.0, 0.4)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_IN)
	stop_listening = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if !stop_listening:
			open()
			stop_listening = true

func _process(delta: float) -> void:
	if !trip: return
	var rect = target.get_rect()
	rect.position = Vector2.ZERO
	if !rect.has_point(target.get_local_mouse_position()):
		trip = false
		close()

extends Control

const DELETION_KEY = &"note_notification_kill_key"
const TIMER_KEY = &"note_notification_timer_key"

## Each control in the notification stack is offset by the previous controls
## size, multiplied by this. Setting x to 0.5 will have every control start
## midway through the previous one on the x axis.
@export var separation_ratio: Vector2 = Vector2(0.0, 1.0)
## Same with ratio, but with flat pixel amounts added after each notification.
@export var separation_flat: Vector2 = Vector2(0, 3.0)
@export var use_corner_decoration: bool = true
@export var use_audio_notification: bool = true

@export_group("Refs")
@export var popup_audio: AudioStreamPlayer
@export var notification_corner_deco: TextureRect
@export var notification_container: Container

var open_notifications: Array[Control] = []

func _ready() -> void:
	hide()

func _add_notification(control: Control, duration: float = 3.0):
	control.offset_transform_enabled = true
	control.offset_transform_visual_only = false
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	control.set_meta(TIMER_KEY, duration)
	notification_container.add_child(control)
	open_notifications.append(control)
	popup_audio.play()
	var target_pos = Vector2.ZERO
	for c in notification_container.get_children():
		if c == control: continue
		if c is Control:
			target_pos += (c.size*separation_ratio)
			target_pos += separation_flat
	control.offset_transform_position = target_pos

func send_basic(text: String, duration: float = 2.0, icon_zoom: float = 1.0):
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	var label = RichTextLabel.new()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 8)
	margin.add_theme_constant_override(&"margin_right", 8)
	margin.add_theme_constant_override(&"margin_top", 8)
	margin.add_theme_constant_override(&"margin_bottom", 8)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.fit_content = true
	label.bbcode_enabled = true
	label.text = text
	hbox.add_child(label)
	margin.add_child(hbox)
	panel.add_child(margin)
	_add_notification(panel, duration)
func send_advanced(scene, duration: float = 2.0):
	var object = null
	if scene is PackedScene:
		object = scene.instantiate()
	elif scene is String:
		object = note.loading.fetch(scene).instantiate()
	elif scene is Control:
		if scene.get_parent() != null:
			scene.get_parent().remove_child(scene)
		object = scene
	elif scene is Callable:
		object = note.loading.fetch("uid://ckwjl0ougs0m6").instantiate()
		object.tooltip(scene)
	
	if object != null:
		_add_notification(object, duration)
func _kill(control: Control):
	control.set_meta(DELETION_KEY, true)
	var t = control.create_tween()
	t.tween_property(control, "modulate:a", 0.0, 0.45)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(control.queue_free)
func _process(delta: float) -> void:
	var was_visible = visible
	visible = notification_container.get_child_count() > 0
	
	if use_corner_decoration:
		if was_visible and !visible:
			notification_corner_deco.modulate.a = 1.0
			notification_corner_deco.show()
		if !was_visible and visible:
			notification_corner_deco.modulate.a = 0.0
			notification_corner_deco.show()
		
		notification_corner_deco.modulate.a = note.util.smooth_toward(
			notification_corner_deco.modulate.a,
			1.0 if visible else 0.0, 3.0, delta
		)
	else:
		notification_corner_deco.hide()
	
	var mouse_inside_notifications = (
		note.controls.hovered_node != null
		and notification_container.is_ancestor_of(note.controls.hovered_node)
	)
	if !mouse_inside_notifications:
		for notify in open_notifications:
			var timer = notify.get_meta(TIMER_KEY, -1.0)
			timer -= delta
			if timer <= 0.0:
				_kill(notify)
				open_notifications.erase.call_deferred(notify)
			notify.set_meta(TIMER_KEY, timer)
	
	var stamp: Vector2 = Vector2.ZERO
	for c in notification_container.get_children():
		if c.has_meta(DELETION_KEY): continue
		if c is Control:
			var cur_off = c.offset_transform_position
			cur_off = note.util.smooth_toward_v2(cur_off, stamp, 6.0, delta)
			c.offset_transform_position = cur_off

			stamp += (c.size*separation_ratio)+separation_flat

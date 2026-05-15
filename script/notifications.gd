extends Control

const DELETION_KEY = &"__note_notification_kill_key"

@export var popup_audio: AudioStreamPlayer
## 0.0 = far left of screen, top of screen, 1.0 = far right of screen, bottom of screen.
## Set this to control where the anchor is for your notifications.
@export var screen_ratio_position: Vector2 = Vector2(0.075, 0.5)
## Each control in the notification stack is offset by the previous controls
## size, multiplied by this. Setting x to 0.5 will have every control start
## midway through the previous one on the x axis.
@export var separation_ratio: Vector2 = Vector2(0.0, 1.0)
## Same with ratio, but with flat pixel amounts added after each notification.
@export var separation_flat: Vector2 = Vector2(3.0, 2)

var _timers: Dictionary[Control,float]

func _ready() -> void:
	child_entered_tree.connect(func(_c): _update_position())
	child_exiting_tree.connect(func(_c): _update_position())

func _prep_control(control: Control):
	control.offset_transform_enabled = true
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
func _update_position():
	size = Vector2.ZERO
	anchor_left = screen_ratio_position.x
	anchor_right = screen_ratio_position.x
	anchor_top = screen_ratio_position.y
	anchor_bottom = screen_ratio_position.y
func send_basic(text: String, icon: Texture2D = null, duration: float = 2.0, icon_zoom: float = 1.0):
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = text
	if icon != null:
		var tex = TextureRect.new()
		tex.texture = icon
		tex.custom_minimum_size = icon.get_size()*icon_zoom
		tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(tex)
	hbox.add_child(label)
	panel.add_child(hbox)
	_prep_control(panel)
	
	_timers[panel] = duration
	popup_audio.play()
	add_child(panel)
func send_representor(representor: String, data = null, duration: float = 2.0) -> Representor:
	var prefab = note.loading_screen.force_fetch(representor) as PackedScene
	if prefab != null:
		var rep = prefab.instantiate() as Representor
		if rep != null:
			rep.represent(data)
			_prep_control(rep)
			_timers[rep] = duration
			popup_audio.play()
			add_child(rep)
			return rep
		return null
	else:
		note.error("Failed to load file path/uid '%s'" % representor)
		return null
func _kill(control: Control):
	var t = control.create_tween()
	t.tween_property(control, "modulate:a", 0.0, 0.45)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(control.queue_free)
	t.tween_callback(_update_position)
func _process(delta: float) -> void:
	var free_keys = []
	for k in _timers:
		if _timers[k] > 0.0:
			_timers[k] -= delta
			if _timers[k] <= 0.0:
				free_keys.append(k)
				k.set_meta(DELETION_KEY, true)
				_kill(k)
	for k in free_keys:
		_timers.erase(k)
	
	var stamp: Vector2 = Vector2.ZERO
	for c in get_children():
		if c.has_meta(DELETION_KEY): continue
		if c is Control:
			var cur_off = c.offset_transform_position
			cur_off = note.util.smooth_toward_v2(cur_off, stamp, 6.0, delta)
			c.offset_transform_position = cur_off

			stamp += (c.size*separation_ratio)+separation_flat

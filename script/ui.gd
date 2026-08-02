extends Node

const DefaultWindowBlackout = Color(0.0,0.0,0.0, 0.2)

const TypeNotifications = preload("uid://bd2xr6domuqt7")
const TypeTooltipManager = preload("uid://ej2vfmjw2dkq")
const TypeFocusGroup = preload("uid://4iwdim3cbvkf")
const TypeControlGuide = preload("uid://b5urykf5xl2tp")
const TypeGuidelet = preload("uid://dautr48g47wu3")

@export_group("Refs")
@export var _blackout: ColorRect
@export var _window_container: Container
@export var _window_root: Container
@export var _internal_tooltip: TypeTooltipManager
@export var _internal_notifications: TypeNotifications
@export var _internal_controlguide: TypeControlGuide
@export var focus: TypeFocusGroup # Focus gets a direct forward due to its size.


var current_window: NoteWindow
var window_fade_time: float = 0.25


func _ready() -> void:
	_blackout.hide()
	_window_root.hide()

func _close(close_shutters: bool = true):
	if current_window != null:
		var win = current_window
		var t = win.create_tween()
		t.tween_property(win, "modulate:a", 0.0, 0.4)
		t.tween_callback(win.queue_free)
		current_window = null
	if close_shutters:
		var fadeout_color = _blackout.color
		fadeout_color.a = 0.0
		var t = create_tween()
		t.tween_property(_blackout, "color", fadeout_color, window_fade_time+0.4)
		t.tween_callback(_blackout.hide)
		t.tween_callback(_window_root.hide)

## Takes a window scene, which could be a path, a packed scene, an already
## created node, or a VMU callback to popup into the viewport, blocking input. 
## This will return the window, before it appears.
func window(window_scene, blackout_color: Color = DefaultWindowBlackout) -> NoteWindow:
	_window_root.show()
	_window_container.show()
	if blackout_color.a > 0.0:
		var blackout_t = create_tween()
		blackout_t.set_ease(Tween.EASE_OUT)
		blackout_t.set_trans(Tween.TRANS_QUAD)
		_blackout.show()
		_blackout.color = blackout_color
		_blackout.color.a = 0.0
		blackout_t.tween_property(_blackout, "color", blackout_color, window_fade_time)
	else:
		_blackout.hide()
	if current_window != null:
		note.warn("Popup window called while window already exists, closing current window.")
		_close(false)
	var new_window: NoteWindow = null
	if window_scene is String:
		new_window = note.loading.fetch(window_scene).instantiate() as NoteWindow
	elif window_scene is PackedScene:
		new_window = window_scene.instantiate()
	elif window_scene is NoteWindow:
		if window_scene.get_parent() != null:
			window_scene.get_parent().remove_child(window_scene)
		new_window = window_scene
	elif window_scene is Callable:
		if window_scene.get_argument_count() == 1:
			new_window = note.loading.fetch("uid://b674weyj11a28").instantiate() as NoteWindow
			var shell: NoteAppShell = new_window.shell
			shell.event_raised.connect(func(evt: NoteAppShell.Event):
				if evt.event_name == &"close_window":
					new_window.close_window()
			)
			shell.callback = window_scene
		else:
			push_error("App VMU Style callback should have 1 argument, of type NoteAppShell")
	_window_container.add_child(new_window)
	current_window = new_window
	new_window.closed.connect(_close)
	
	var t = _window_container.create_tween()
	_window_container.modulate.a = 0.0
	t.tween_property(_window_container, "modulate:a", 1.0, 0.4)
	
	return new_window

## Summons a tooltip. [b]Call this per frame[/b].[br][br]
## Tooltip scene can be a string path to load, a callable to use App VMU style creation, a packed scene,
## or a node(that will be freed when the tooltip closes).[br][br]Data will be passed to the instantiated node
## if it has a [code]tooltip(data)[/code] method. Priority can be used to overwrite active tooltip calls.
func tooltip(tooltip_scene, data=null, priority:int=0):
	_internal_tooltip.request(tooltip_scene, data, priority)

## Gets the current input texture map being used by the control guide.
## You can use this to get texture icons for your action guides.
func control_guide_icons() -> InputTextureMap:
	return _internal_controlguide.input_icon_theme
## Clears the control guide, so you can add the updated guidelets with _add.
## Calling begin but never adding a guidelet will leave the control guide hidden.
## [br][br]My personal recommendation is to focus on using the control guide primarily
## through the Phase system.
func control_guide_begin():
	_internal_controlguide.clear_controls()
## Clears the control guide, so you can add the updated guidelets with _add.
## Calling begin but never adding a guidelet will leave the control guide hidden.
func control_guide_add(action_name: String, icons: Array[Texture2D] = []) -> TypeGuidelet:
	var guidelet = _internal_controlguide.make_manual(action_name)
	for i in icons:
		guidelet.add_icon_manual(i)
	return guidelet

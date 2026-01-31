extends Container

@export_category("Design")
## If you want to call into tooltips from physics frames or from an intermittant
## code path this can be used to make sure it won't flicker.
@export var pity_time: float = 0.2
@export var fade_time: float = 0.2
@export var tip_container: Container

var _timer: float = 0.0
var _active: bool = false
var _current_item: Control = null
var _current_priority: int = -INF
var _current_package: PackedScene
var _current_data

func _reset_pos():
	reset_size()
	offset_bottom = 0.0
	offset_left = 0.0
	offset_right = 0.0
	offset_top = 0.0
	set_screen_position(1.0, 1.0)

## coordinates are given in 0-1 where they lay on the screen: eg 0.0,0.5 will give you left centered
## popups.
func set_screen_position(x: float, y: float):
	anchor_left = x
	anchor_right = x
	anchor_top = y
	anchor_bottom = y
## Sets padding on the popup container, useful for maintaining a constant offset
## from an edge, rather than a proportion.
func set_padding(left_px: float, right_px: float, top_px: float, bottom_px: float, h_direction: Control.GrowDirection = Control.GROW_DIRECTION_BOTH, v_direction: Control.GrowDirection = Control.GROW_DIRECTION_BOTH):
	add_theme_constant_override("margin_left", left_px)
	add_theme_constant_override("margin_right", right_px)
	add_theme_constant_override("margin_top", top_px)
	add_theme_constant_override("margin_bottom", bottom_px)
	grow_horizontal = h_direction
	grow_vertical = v_direction
func _set_tooltip_package(prefab: PackedScene, data, priority: int):
	_clear_tooltip_package()
	_current_item = prefab.instantiate()
	tip_container.add_child(_current_item)
	if _current_item.has_method("tooltip"):
		_current_item.tooltip(data)
	_current_priority = priority
	_current_data = data
	_current_package = prefab
	_timer = 0.0
	_active = true
	set_deferred("size", Vector2.ZERO)
	show()
	call_deferred("_reset_pos")
func _clear_tooltip_package():
	if _current_item != null:
		_current_item.queue_free()
	_current_data = null
	_current_package = null
	_current_item = null
	_reset_pos()

func request_simple(title:String = "", body:String = "", priority: int = 0):
	request_packed(preload("res://addons/note/prefab/default_tooltips/simple_tooltip.tscn"), [title, body], priority)

## Takes in a path or UID to load, and instantiates it as the tooltip. Data is passed in to a method
## called "tooltip" if it exists.
func request_string(prefabPath:String, data = null , priority: int = 0):
	request_packed(note.loading_screen.force_fetch(prefabPath), data, priority)

## Takes in an already loaded packed scene, and instantiates it as the tooltip. Data is passed in to a method
## called "tooltip" if it exists.
func request_packed(prefab:PackedScene, data = null, priority: int = 0):
	# If the data is potentially a refresh:
	if _active:
		# If the data is new:
		if prefab != _current_package or data != _current_data:
			if priority >= _current_priority:
				_set_tooltip_package(prefab, data, priority)
		# If the data is the same:
		else:
			_timer = 0.0
	else:
		_set_tooltip_package(prefab, data, priority)

func _process(delta: float) -> void:
	if _active:
		modulate.a = clamp(remap(_timer, pity_time, pity_time+fade_time, 1.0, 0.0), 0.0, 1.0)
		_timer += delta
		if _timer >= fade_time+pity_time:
			_clear_tooltip_package()
			_active = false
			_timer = 0.0
			hide()
	else:
		modulate.a = 0.0

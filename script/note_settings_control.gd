## This script can be added to any other control that represents
## a value, and given a key to look into the current save session
## and update accordingly. Use if the value is a basic type like
## String, Float, Int, or Bool.

extends Node
class_name NoteSettingsControl

signal updated_save

@export var save_setting: StringName = &""
@export var side_effect: StringName = &""

var parent

func _get_value_from_save() -> Variant:
	var save = note.current_session
	if save != null:
		return save.get(save_setting)
	return null
func _set_value(new_value):
	var save = note.current_session
	if save != null:
		save.set(save_setting, new_value)
		if side_effect != &"":
			var count = save.get_method_argument_count(side_effect)
			if count == 0:
				save.call(side_effect)
			else:
				save.call(side_effect, new_value)

func _ready() -> void:
	parent = get_parent()
	var val = _get_value_from_save()
	if val == null:
		note.warn("Failed to get the value %s from the save file" % save_setting)
		queue_free()
		return
	if parent is CheckBox or parent is CheckButton:
		parent.button_pressed = val
		parent.toggled.connect(func(new_value):
			_set_value(new_value)
			updated_save.emit()
		)
		return
	if parent is Button:
		parent.pressed.connect(func():
			var current_val = _get_value_from_save()
			_set_value(!current_val)
			updated_save.emit()
		)
		return
	if parent is Slider:
		parent.value = val
		parent.value_changed.connect(func(new_value):
			_set_value(new_value)
			updated_save.emit()
		)
		return
	if parent is SpinBox:
		parent.value_changed.connect(func(new_value):
			_set_value(new_value)
			updated_save.emit()
		)
		return

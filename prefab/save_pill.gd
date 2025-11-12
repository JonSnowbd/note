extends Control

## Internal node type used to manage saving, loading, and deleting
## saves when using non-simple save strategies

@export var label: Label
@export var primary_button: Button
@export var menu_button: MenuButton

signal selected
signal deleting

@onready var _nt = get_tree().root.get_node("note")

func _ready() -> void:
	primary_button.pressed.connect(func():
		selected.emit()
	)
	menu_button.get_popup().index_pressed.connect(func(ind):
		if ind == 0:
			deleting.emit()
	)
	pivot_offset = size*0.5

func _physics_process(delta: float) -> void:
	if _nt.controls.is_mouse_and_keyboard() and menu_button.disabled:
		var distance = get_local_mouse_position().distance_to(size*0.5)
		modulate.a = 1.0-clamp(distance/350.0, 0.0, 0.5)
	else:
		modulate.a = 1.0

func set_state_save_exists(save_alias: String):
	label.text = save_alias
	primary_button.text = tr("Select", "'Select a save', used on a button on the save profile")
	menu_button.disabled = false
func set_state_waiting_for(save_alias: String):
	label.text = tr("Empty Save Slot", "A save file name used to show an empty save slot")
	primary_button.text = tr("Create", "'Create a save', used on a button on the save profile")
	menu_button.disabled = true
	menu_button.hide()

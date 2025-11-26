extends Control

@export var copy_from: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if copy_from is Slider:
		copy_from.value_changed.connect(copy_slider)
	if copy_from is ProgressBar:
		copy_from.value_changed.connect(copy_progress_bar)


func copy_slider(_dud):
	set("value", copy_from.get("value"))
	set("min_value", copy_from.get("min_value"))
	set("max_value", copy_from.get("max_value"))

func copy_progress_bar(_dud):
	set("min_value", copy_from.get("min_value"))
	set("max_value", copy_from.get("max_value"))
	set("value", copy_from.get("value"))
	set("step", copy_from.get("step"))
	set("page", copy_from.get("page"))

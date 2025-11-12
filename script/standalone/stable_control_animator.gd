extends Object
class_name StableControlAnimator

## This utility attaches to a control, and applies transformations smoothly
## and in a very stable manner, surviving re-layouts and resizes. Note this can
## have bad performance on controls that are in containers with many siblings.

var target: Control :
	set(val):
		if target != val:
			target = val
			hard_refresh()
var origin: Vector2 = Vector2(0.5, 0.5) :
	set(val):
		if origin != val:
			origin = val
			target.pivot_offset = target.size * origin
			print("Offset: %.2f %.2f" % [target.pivot_offset.x, target.pivot_offset.y])
var offset: Vector2 = Vector2.ZERO :
	set(val):
		if offset != val:
			var diff = val - offset
			offset = val
			if target != null:
				target.position += diff
var rotation_degrees: float = 0.0 :
	set(val):
		if rotation_degrees != val:
			var diff = val - rotation_degrees
			rotation_degrees = val
			if target != null:
				target.rotation_degrees += diff
var scale: Vector2 = Vector2.ONE:
	set(val):
		if scale != val:
			scale = val

## If assigned, this control self destructs when its over.
var dependant_tween: Tween :
	set(val):
		if dependant_tween != val:
			dependant_tween = val
			dependant_tween.finished.connect(func():
				free()
			)

func _init(control: Control) -> void:
	target = control
	var parent: Container = target.get_parent() as Container
	if parent != null:
		parent.sort_children.connect(_apply)

## Triggers a hard refresh of the parent container.
## Useful if you fear an action may have desynced the control's transform.
func hard_refresh():
	if target == null:
		return
	var parent = target.get_parent()
	if parent is Container:
		parent.queue_sort()

func reset():
	origin = Vector2(0.5, 0.5)
	scale = Vector2.ONE
	rotation_degrees = 0.0
	offset = Vector2.ZERO
	hard_refresh()

func _apply():
	target.pivot_offset = target.size*origin
	target.position += offset
	target.rotation_degrees += rotation_degrees

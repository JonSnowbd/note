@tool
extends Node2D
class_name CuteAttachment2D

@export var distance: float = 0.5
@export var facing_offset:float = -0.1
@export var raise: float = 0.5

func stow(duration: float = 0.2, subt: Tween = null):
	pass
func unstow(duration: float = 0.2, subt: Tween = null):
	pass

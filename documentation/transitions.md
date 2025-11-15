# Transition Guide

The transition system in Note is independant of the other features, but is often
used by those features. It is simply a texture rect that displays a screen capture, with
a shader that fades from that screen capture, to transparency to reveal the new content.

Therefore you can use it in many different scenarios.

```gdscript
func teleport_player(new_location: Vector2):
	note.transition.trigger(1.0) # Second long transition to demonstrate.
	player.global_position = new_location
	camera.global_position = new_location
```

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

![A demonstration of the above function](/documentation/transition_demo.gif)

## How it works

When trigger is called:

- A snapshot of the viewport is taken, and uploaded to the transition Texture Rect that
is on the Note autoload canvas layer, well above everything else.
- The Texture Rect is then shown
- A Tween smoothly transitions the `completion` uniform of the shader from 0.0 to 1.0
- After this is done, the Texture Rect is hidden

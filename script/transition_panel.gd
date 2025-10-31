extends TextureRect

## Callback for tweens to modify the shader
## parameter.
func _tween_callback(new_value: float):
	if material is ShaderMaterial:
		material.set_shader_parameter("progress", new_value)

## Takes a snapshot of the viewport, sends the screen texture into the screen cover,
## then transitions the material's parameter from 0.0 to 1.0 and hides the cover.
## If you're transitioning a level manually, just call this, then change the level.
func trigger(time: float = 0.33):
	var img = get_viewport().get_texture().get_image()
	texture = ImageTexture.create_from_image(img)
	show()
	if material is ShaderMaterial:
		material.set_shader_parameter("progress", 0.0)
		material.set_shader_parameter("seed", randf()*32000.0)
	var t = create_tween()
	t.tween_method(_tween_callback, 0.0, 1.0, time)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_OUT)
	t.tween_callback(hide)

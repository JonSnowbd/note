extends ChainFX
class_name ChainNoteCameraFollow

## This interacts with the scene's NoteCamera2D and makes it follow the context.


func _start(data):
	var cam = get_viewport().get_camera_2d()
	print(cam.name)
	if cam is NoteCamera2D:
		print("Hello???")
		cam.follow(data)

extends RefCounted
class_name NoteStatCoreEffector

## Higher priority = executed first
var effector_priority: float = 0.0
var effector_duration: float = -1.0
var effector_lifetime: float = -1.0
func effector_init(obj: NoteStatCore):
	pass
func effector_deinit(obj: NoteStatCore):
	pass
func effector_apply(obj: NoteStatCore):
	pass
func effector_tick(obj: NoteStatCore, dt: float):
	pass
func effector_modify(obj: NoteStatCore, event):
	pass

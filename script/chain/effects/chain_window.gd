extends ChainFX
class_name ChainWindow

@export var window_packed: PackedScene
@export_file("*.tscn", "*.scn") var window_path: String
@export var fade_in: float = 0.4
@export var interrupt_focus: bool = true

var current_window: NoteWindow

func _start(data):
	var target = window_packed if window_packed != null else window_path
	current_window = note.ui.popup_window(target, fade_in, interrupt_focus)
	on_start.emit()
func _done() -> bool:
	return note.ui.current_window != current_window

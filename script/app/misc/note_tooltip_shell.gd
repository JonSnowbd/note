extends MarginContainer

@export var shell: NoteAppShell

func tooltip(view_function: Callable):
	shell.callback = view_function
	shell.trigger_relayout()

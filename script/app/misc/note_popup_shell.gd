extends NoteAppShell

var callback: Callable

func initialize():
	pass

func view():
	if callback.is_valid():
		callback.call(self)

extends NoteAppFragment

@export var button_reference: Button

func fragment_init(shell: NoteAppShell):
	button_reference.pressed.connect(_pressed)
func fragment_update(shell: NoteAppShell, props: Dictionary[StringName,Variant]):
	button_reference.text = props.get(&"text", "Default Button")

func _pressed():
	raise_event(&"pressed")

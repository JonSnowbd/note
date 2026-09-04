extends NoteAppFragment

@export var rich_text_label: RichTextLabel

func fragment_update(shell: NoteAppShell, props: Dictionary[StringName,Variant]):
	rich_text_label.text = props.get(&"text", "Default Text")

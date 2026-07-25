extends NoteAppFragment

@export var box: BoxContainer
@export var margin: MarginContainer

func fragment_update(shell: NoteAppShell, props: Dictionary[StringName,Variant]):
	box.vertical = !props.get(&"horizontal", false)
	var pad = props.get(&"padding", 4)
	margin.add_theme_constant_override(&"margin_left", pad)
	margin.add_theme_constant_override(&"margin_top", pad)
	margin.add_theme_constant_override(&"margin_right", pad)
	margin.add_theme_constant_override(&"margin_bottom", pad)

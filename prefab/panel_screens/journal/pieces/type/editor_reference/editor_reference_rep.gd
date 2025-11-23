@tool
extends MarginContainer

const RefType = preload("uid://ctaymxqonp17p")

@export var overall_icon_container: Control
@export var name_label: LinkButton
@export var desc_label: Label
@export var icon: TextureRect
@export var inherit_button: LinkButton

func begin(target: RefType):
	if is_part_of_edited_scene(): return
	update_to_spec(target)
	name_label.pressed.connect(clicked_link.bind(target))
	inherit_button.pressed.connect(clicked_inherit.bind(target))
	target.changed.connect(update_to_spec.bind(target))
func update_to_spec(target: RefType):
	name_label.text = target.make_real_name(target.path)
	if name_label.text == "":
		name_label.text = tr("No file selected")
	name_label.modulate = target.color
	desc_label.text = target.description
	inherit_button.hide()

	if Engine.is_editor_hint() and !target.path.is_empty() and FileAccess.file_exists(target.path):
		if target.cached_scene is PackedScene:
			inherit_button.show()
		EditorInterface.get_resource_previewer()\
		.queue_resource_preview(target.path, self, &"preview_callback", target.cached_scene)

func clicked_inherit(target: RefType):
	if target.path.is_empty():
		return
	if ResourceLoader.exists(target.path):
		if target.cached_scene is PackedScene:
			open_scene(target.path, target.cached_scene, true)
func clicked_link(target: RefType):
	if target.path.is_empty():
		return
	if ResourceLoader.exists(target.path):
		if target.cached_scene is Resource:
			EditorInterface.edit_resource(target.cached_scene)
		if target.cached_scene is GDScript:
			EditorInterface.edit_script(target.cached_scene)
		if target.cached_scene is PackedScene:
			open_scene(target.path, target.cached_scene, false)

func open_scene(scene: String, packed: PackedScene, inherited: bool = false):
	EditorInterface.open_scene_from_path(scene, inherited)
	await get_tree().process_frame
	var inst = packed.instantiate()
	if inst is Node2D or inst is Control or inst is CanvasLayer or inst is CanvasItem:
		EditorInterface.set_main_screen_editor("2D")
	if inst is Node3D:
		EditorInterface.set_main_screen_editor("3D")
	inst.queue_free()

func preview_callback(path: String, preview: Texture2D, thumbnail: Texture2D, userdata):
	if thumbnail == null:
		overall_icon_container.show()
		if userdata is PackedScene:
			icon.texture = EditorInterface.get_editor_theme().get_icon("PackedScene", "EditorIcons")
		elif userdata is GDScript:
			icon.texture = EditorInterface.get_editor_theme().get_icon("Script", "EditorIcons")
		else:
			overall_icon_container.hide()
	else:
		overall_icon_container.show()
		icon.texture = thumbnail

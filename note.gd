@tool
extends EditorPlugin

const welcome_text: String = """[br][b]Thank you for choosing Note[/b] as your game's manager![br]Create a resource of type\
 [code]NoteDeveloperSettings[/code] and [br] assign it in your Project Settings: [code]Addons/Note/Settings[/code][br]\
 and don't forget to set your game's Main Scene to [code]res://addons/note/ENTRY.tscn[/code] in [code]Run/Main Scene[/code]
"""

var editor_plugin
var main_panel_inst: Control

func _enable_plugin() -> void:
	add_autoload_singleton("note", "res://addons/note/scene/note_center.tscn")

func _disable_plugin() -> void:
	remove_autoload_singleton("note")

func _resource_saved(res: Resource):
	if res is NoteDeveloperSettings:
		var current_settings = ProjectSettings.get_setting("addons/note/settings", "")
		if current_settings == "":
			var path = res.resource_path
			
			print_rich("Note automatically loaded your new developer settings: '%s'[br]If this was not\
 desired, please correct this in Project Settings Addons/Note/Settings" % path)
			
			ProjectSettings.set_setting("addons/note/settings", path)

func _enter_tree() -> void:
	resource_saved.connect(_resource_saved)
	
	if not ProjectSettings.has_setting("addons/note/settings"):
		ProjectSettings.set_setting("addons/note/settings", "")
		ProjectSettings.set_initial_value("addons/note/settings", "")
		print_rich(welcome_text)
	ProjectSettings.set_as_basic("addons/note/settings", true)
	ProjectSettings.add_property_info({
		"name": "addons/note/settings",
		"type": TYPE_STRING,
		"editor_description": "Developer settings for note. Should be a resource that extends\
		[code]NoteDeveloperSettings[/code]",
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.res,*.tres" 
	})
	editor_plugin = preload("uid://duvuj8wjqpcci").new()
	add_inspector_plugin(editor_plugin)
	
	main_panel_inst = preload("uid://1baqu2co3orh").instantiate()
	main_panel_inst.hide()
	EditorInterface.get_editor_main_screen().add_child(main_panel_inst)

func _exit_tree() -> void:
	remove_inspector_plugin(editor_plugin)
	if main_panel_inst != null:
		main_panel_inst.queue_free()

func _make_visible(visible: bool) -> void:
	if main_panel_inst != null:
		main_panel_inst.visible = visible
func _get_plugin_name() -> String:
	return "Note"
func _has_main_screen() -> bool:
	return true
func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")

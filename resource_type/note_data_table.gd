@tool
extends Resource
class_name NoteDataTable

## A simple data structure for lazy-loading, preloading, and referencing
## many assets or functions via a primary key. A must-have if you want a quick & easy way
## to serialize data safely without using a resource reader in your save file.
## Example use cases: A datatable for items, so you can serialize the inventory of
## the player via the primary keys rather than serializing the resource(unsafe)
## Remember to register the data table in your note settings.

@export_storage var keys: Array[StringName]
@export_storage var path: Array[StringName]

@export_tool_button("Edit Datatable") var _edit_datatable = editor_begin_edit

## If true every asset will be shadowloaded, and pre-warmed.
## Not recommended if this table will contain many large assets.
## Prefer to predict keys that you think will show up soon, and
## call [code]pre_warm(your_key)[/code] appropriately.
@export var auto_warm: bool = false

func editor_begin_edit():
	if Engine.is_editor_hint():
		pass

var instances: Dictionary[StringName,Object] = {}

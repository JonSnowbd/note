@icon("res://addons/note/texture/icon/pecs/entity_marker.svg")
extends Node
class_name PECSEntityMarker

const ENTMARK_METATAG = &"__pecs_entity_marker"

@export var node: Node

var core: PECSCore
var component_handles: Dictionary[Script,int]
var side_effects: Array[PECSSideEffect]
var relationships: Dictionary[Script,PECSEntityMarker] = {}
## General use entity data store for systems.
var blackboard: Dictionary

func _enter_tree() -> void:
	_setup_entity()
func _ready() -> void:
	_setup_entity()

func _setup_entity() -> void:
	if core != null: return
	var parent = get_parent()
	if parent != null:
		parent.set_meta(ENTMARK_METATAG, self)
	while parent != null:
		if parent.has_meta(PECSCore.CORE_METATAG):
			core = parent.get_meta(PECSCore.CORE_METATAG)
			core.notify_new_entity(self)
			break
		parent = parent.get_parent()

# Strips away every component and frees the node.
# This is an immediate effect, every lens will be updated
# and every component will be gone when you call this.
func mark_for_deletion():
	if core != null:
		for scr in component_handles.keys():
			remove_component(scr)
		core.notify_lost_entity(self)
		node.queue_free()
	else:
		note.warn("Entity %s requested deletion without a core." % name)

func add_component(component: Script, value = null):
	if core != null:
		if value == null:
			core.entity_add_component(self, component, component.new())
		else:
			core.entity_add_component(self, component, value)
	else:
		note.warn("Entity %s requested component without a core." % name)
func has_component(component: Script) -> bool:
	if core != null:
		return core.entity_has_component(self, component)
	else:
		note.warn("Entity %s requested component without a core." % name)
	return false
func get_component(component: Script) -> Variant:
	if core != null:
		return core.entity_get_component(self, component)
	else:
		note.warn("Entity %s requested component without a core." % name)
	return null
## Removes the component from the component registry and immediately reflects
## the change in every lens. If you are doing this in a lens' get_entities()
## loop, prefer deferred, or track them and remove after the loop.
func remove_component(component: Script):
	if core != null:
		core.entity_remove_component(self, component)
	else:
		note.warn("Entity %s requested component without a core." % name)
func remove_component_deferred(component: Script):
	call_deferred(&"remove_component", component)
func add_relation(relation: Script, to: PECSEntityMarker):
	if core != null:
		core.entity_add_relation(self, relation, to)
	else:
		note.warn("Entity %s requested bond without a core." % name)
func remove_relation(relation: Script):
	if core != null:
		core.entity_remove_relation(self, relation)
	else:
		note.warn("Entity %s requested bond without a core." % name)
func get_relation(relation: Script) -> PECSEntityMarker:
	return relationships.get(relation,null)
func has_relation(relation: Script, to_specifically: PECSEntityMarker = null) -> bool:
	if !relationships.has(relation):
		return false
	if to_specifically != null:
		if relationships[relation] == to_specifically:
			return true
		else:
			return false
	return true

func add_side_effect(fx: PECSSideEffect):
	side_effects.append(fx)
	fx.setup(self)

## Component is the script name that you are updating. Marks a component
## as updated. Used for side effect mutation.
func mark_updated(component: Script):
	if core != null:
		core.entity_mark_component_updated(self, component)
	else:
		note.warn("Entity %s requested component without a core." % name)

extends Node
class_name PECSEntityMarker

class RelationshipData:
	var target: PECSEntityMarker
	var data: Variant

## Convenience method to mark a node as an entity during runtime.
## Please prefer to place markers in your nodes manually.
static func mark(node: Node) -> PECSEntityMarker:
	var marker = PECSEntityMarker.new()
	node.add_child(marker)
	return marker

## Convenience method to create an entity that belongs to no real node.
static func make_transient(transient_core: PECSCore) -> PECSEntityMarker:
	var marker = PECSEntityMarker.new()
	marker.transient = true
	marker.core = transient_core
	marker.core.notify_new_entity(marker)
	return marker

const ENTMARK_METATAG = &"__pecs_entity_marker"

var core: PECSCore
var enabled: bool = true :
	set(val):
		if enabled != val:
			enabled = val
			if enabled and core != null:
				core.notify_new_entity(self)
			elif !enabled and core != null:
				core.notify_lost_entity(self)

var component_handles: Dictionary[Script,int]
var side_effects: Array[PECSSideEffect]
var frame_tags: Array = []
var transient: bool = false
var is_setup_complete: bool = false
var relationships: Dictionary[Script,Array] = {}

func _hook_into_core(new_core: PECSCore):
	core = new_core
	if enabled:
		core.notify_new_entity(self)

func _enter_tree() -> void:
	var parent = get_parent()
	if parent != null:
		parent.set_meta(ENTMARK_METATAG, self)
	if transient or is_setup_complete:
		return
	while parent != null:
		if parent.has_meta(PECSCore.CORE_METATAG):
			core = parent.get_meta(PECSCore.CORE_METATAG)
			if enabled:
				core.notify_new_entity(self)
			break
		parent = parent.get_parent()
func _exit_tree() -> void:
	if core != null:
		core.notify_lost_entity(self)
		core = null
	var parent = get_parent()
	if parent != null:
		parent.remove_meta(ENTMARK_METATAG)

func add_component(component: Script, value):
	if core != null:
		core.entity_add_component(self, component, value)
	else:
		note.warn("Entity %s requested component without a core.")
func has_component(component: Script) -> bool:
	if core != null:
		return core.entity_has_component(self, component)
	else:
		note.warn("Entity %s requested component without a core.")
	return false
func get_component(component: Script) -> Variant:
	if core != null:
		return core.entity_get_component(self, component)
	else:
		note.warn("Entity %s requested component without a core.")
	return null
func remove_component(component: Script):
	if core != null:
		core.entity_remove_component(self, component)
	else:
		note.warn("Entity %s requested component without a core.")

func add_relation(relation: Script, to: PECSEntityMarker, value = null):
	if core != null:
		core.entity_bond(self, relation, to, value)
	else:
		note.warn("Entity %s requested bond without a core.")
func remove_relation(relation: Script, to: PECSEntityMarker):
	if core != null:
		core.entity_unbond(self, relation, to)
	else:
		note.warn("Entity %s requested bond without a core.")
func get_relations(relation: Script) -> Array[PECSEntityMarker]:
	var results: Array[PECSEntityMarker] = []
	var potentials = relationships.get_or_add(relation, [])
	for i: RelationshipData in potentials:
		results.append(i.target)
	return results
func has_relation(relation: Script, to: PECSEntityMarker) -> bool:
	var potentials = relationships.get_or_add(relation, [])
	for i: RelationshipData in potentials:
		if i.target == to:
			return true
	return false
func get_relation_data(relation: Script, to: PECSEntityMarker) -> Variant:
	var potentials = relationships.get_or_add(relation, [])
	for i: RelationshipData in potentials:
		if i.target == to:
			return i.data
	return null

func add_side_effect(fx: PECSSideEffect):
	side_effects.append(fx)
	fx.setup(self)

## Component is the script name that you are updating. new_value may be optionally
## passed for components that use a non-reference type under the hood such as Vector2.
func mark_updated(component: Script, new_value = null):
	if core != null:
		core.entity_mark_component_updated(self, component, new_value)
	else:
		note.warn("Entity %s requested component without a core.")

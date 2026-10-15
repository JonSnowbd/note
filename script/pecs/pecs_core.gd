@tool
@icon("res://addons/note/texture/icon/pecs/core.svg")
extends Node
class_name PECSCore

## Where the ECS should be automatically run for you.
enum AutorunTarget {
	## Nowhere, will not tick by itself, this is for custom control.
	NONE,
	## Runs in _process, recommended for most use cases
	PROCESS,
	## Runs in _physics_process, recommended for games/scenarios that do a lot
	## of physics work with bodies.
	PHYSICS_PROCESS
}

const CORE_METATAG = &"__pecs_core_meta_marker"

class Lens extends RefCounted:
	signal entity_added(ent: PECSEntityMarker)
	signal entity_lost(ent: PECSEntityMarker)
	signal entity_mutated(ent: PECSEntityMarker, component: Script)
	var filter_needs: Array[Script] = []
	var filter_without: Array[Script] = []
	var filter_with_relationship: Array[Script] = []
	var dirty_lens: bool = true
	var list: Array[PECSEntityMarker] = []
	func _argfix(component: Script, ent: PECSEntityMarker):
		entity_mutated.emit(ent,component)
	func consider(ent: PECSEntityMarker):
		var already_listening: bool = list.has(ent)
		var is_valid: bool = true
		for component_required in filter_needs:
			if !ent.has_component(component_required):
				is_valid = false
				break
		for component_not_wanted in filter_without:
			if ent.has_component(component_not_wanted):
				is_valid = false
				break
		if already_listening and !is_valid:
			ent.mutated.disconnect(entity_mutated.emit)
			list.erase(ent)
			entity_lost.emit(ent)
		if !already_listening and is_valid:
			ent.mutated.connect(_argfix.bind(ent))
			list.append(ent)
			entity_added.emit(ent)
	func get_entities() -> Array[PECSEntityMarker]:
		return list
	func setup_with(components: Array[Script]):
		filter_needs = components
		dirty_lens = true
	func setup_without(components: Array[Script]):
		filter_without = components
		dirty_lens = true
	func setup_with_relations(relationships: Array[Script]):
		filter_with_relationship = relationships
		dirty_lens = true

@export_file("*.tscn", "*.scn") var prewarm_assets: Array[String] = []
@export var root_nodes: Dictionary[StringName, Node] = {} :
	set(val):
		root_nodes = val
		update_configuration_warnings()
@export var default_root: StringName = &"" :
	set(val):
		default_root = val
		update_configuration_warnings()
@export var auto_run: AutorunTarget = AutorunTarget.NONE

var component_store: Dictionary[Script,Array] = {}
var systems: Array[PECSSystem] = []
var observers: Array[PECSObserver] = []
var partitions: Array[PECSPartition] = []

var entities: Array[PECSEntityMarker] = []
var entity_index: Dictionary[PECSEntityMarker, int]

var _component_holes: Dictionary[Script,Array] = {}
var _queued_events: Array = []
var _queued_event_values: Array = []

var maintained_lenses: Array[Lens] = []
var relevant_lenses: Dictionary[Script, Array] = {}
var blackboard: Dictionary[StringName,Variant] = {}
var _immediate_observers: Array[PECSObserver] = []
var _deferred_observers: Array[PECSObserver] = []
var _in_run: bool = false
var _began: bool = false

func _get_configuration_warnings() -> PackedStringArray:
	var warns = []
	if process_priority >= 0:
		warns.append("Physics and Regular Process priority should be <0 so systems runs before your entities.")
	if root_nodes.is_empty():
		warns.append("You need to assign atleast one root node.")
	if default_root.is_empty():
		warns.append("Default Root should not be empty, set it to one of the root nodes from the dictionary above.")
	if !root_nodes.has(default_root):
		warns.append("Default Root must point to a StringName in the dictionary above.")
	return warns

func _set(property: StringName, value: Variant) -> bool:
	if property == &"process_priority" or property == &"process_physics_priority":
		update_configuration_warnings()
	return false

func print_core_state():
	note.info("Core State [b]%s[/b] with the following Systems/Observers/Partitions:" % name, "PECS")
	for sys in systems:
		note.info("[b]%s[/b]" % sys.name, "SYS")
	for obs in observers:
		note.info("[b]%s[/b]" % obs.name, "OBS")
	for par in partitions:
		note.info("[b]%s[/b]" % par.name, "PAR")

func _find_entities(in_node: Node, accumulator: Array):
	if in_node is PECSEntityMarker:
		accumulator.append(in_node)
	for c in in_node.get_children():
		_find_entities(c, accumulator)
func _ready() -> void:
	if Engine.is_editor_hint(): return
	for asset in prewarm_assets:
		if !note.loading_screen.is_cached(asset):
			note.loading_screen.shadow_load(asset)
	for node in root_nodes.values():
		node.set_meta(CORE_METATAG, self)
	for i in get_children():
		if i is PECSSystem:
			system_add_via_node(i)
		if i is PECSObserver:
			observer_add_via_node(i)
		if i is PECSPartition:
			partition_add_via_node(i)
	for sys in systems:
		sys.setup(self)
	for obs in observers:
		obs.setup(self)
	for par in partitions:
		par._initialize(self)
	_began = true
	
	var pre_existing = []
	for root_key in root_nodes.keys():
		_find_entities(root_nodes[root_key], pre_existing)
	for e in pre_existing:
		if e is PECSEntityMarker:
			notify_new_entity(e)

func instantiate_blank_entity(root_override: StringName = &"") -> PECSEntityMarker:
	var destination = default_root if root_override.is_empty() else root_override
	var inst = PECSEntityMarker.new()
	notify_new_entity(inst)
	root_nodes[destination].call_deferred("add_child", inst)
	return inst
func instantiate_wrapped_entity(wrapper: Node, root_override: StringName = &"") -> PECSEntityMarker:
	var destination = default_root if root_override.is_empty() else root_override
	if wrapper.get_parent() != null:
		wrapper.get_parent().remove_child(wrapper)
	var inst = PECSEntityMarker.new()
	wrapper.add_child(inst)
	inst.node = wrapper
	notify_new_entity(inst)
	root_nodes[destination].call_deferred("add_child", wrapper)
	return inst
func instantiate_entity(scene: PackedScene, root_override: StringName = &"") -> PECSEntityMarker:
	var destination = default_root if root_override.is_empty() else root_override
	var parent = root_nodes[destination]
	var inst = scene.instantiate()
	for c in inst.get_children():
		if c is PECSEntityMarker:
			c.core = self
			notify_new_entity(c)
			parent.call_deferred("add_child", inst)
			return c
	return null
func instantiate_entity_s(scene: String, root_override: StringName = &"") -> PECSEntityMarker:
	var packed_scene = note.loading_screen.force_fetch(scene)
	return instantiate_entity(packed_scene, root_override)

func _comb(ent: PECSEntityMarker, node: Node):
	for c in node.get_children():
		if c is PECSBundler:
			if !c.bundle_ran:
				c.execute(ent)
				c.bundle_ran = true
		if c is PECSSideEffect:
			ent.add_side_effect(c)
func notify_new_entity(ent: PECSEntityMarker):
	var ind = len(entities)
	ent.core = self
	entities.append(ent)
	entity_index[ent] = ind
	var true_node = ent.node
	if true_node != null:
		_comb(ent, true_node)
	_comb(ent, ent)
	for l in maintained_lenses:
		l.consider(ent)
func notify_lost_entity(ent: PECSEntityMarker):
	var ind = entity_index.get(ent, -1)
	if ind != -1:
		entities[ind] = null
	for l in maintained_lenses:
		l.list.erase(ent)

func component_add(component: Script):
	if !component_store.has(component):
		component_store[component] = []
		_component_holes[component] = []

## Returns true if an entity has a component.
func entity_has_component(entity: PECSEntityMarker, component: Script) -> bool:
	return entity.component_handles.has(component)
## Reserves a spot in the component store 
func entity_add_component(entity: PECSEntityMarker, component: Script, value: Variant) -> void:
	component_add(component)
	var ind = len(component_store[component])
	if value is PECSComponent:
		value.component_entity = entity
	var using_hole: bool = false
	if len(_component_holes[component]) > 0:
		ind = _component_holes[component].pop_front()
		using_hole = true
	if using_hole:
		component_store[component][ind] = value
	else:
		component_store[component].append(value)
	entity.component_handles[component] = ind
	
	var related_lenses = relevant_lenses.get_or_add(component, [])
	for lens in related_lenses:
		lens.consider(entity)
	entity.mark_updated(component)

func entity_remove_component(entity: PECSEntityMarker, component: Script) -> void:
	var ind = entity.component_handles[component]
	component_store[component][ind] = null
	_component_holes[component].append(ind)
	entity.component_handles.erase(component)
	var related_lenses = relevant_lenses.get_or_add(component, [])
	for lens in related_lenses:
		lens.consider(entity)
func entity_add_relation(source: PECSEntityMarker, relation: Script, target: PECSEntityMarker):
	if source.relationships.has(relation):
		if source.relationships[relation] != null and is_instance_valid(source.relationships[relation]):
			note.warn("%s added relation %s, but it already had one pointing to %s" % [
				source.name,
				str(relation),
				target.name
			])
	source.relationships[relation] = target
	var related_lenses = relevant_lenses.get_or_add(relation, [])
	for lens in related_lenses:
		lens.consider(source)
func entity_remove_relation(source: PECSEntityMarker, relation: Script):
	source.relationships.erase(relation)
	var related_lenses = relevant_lenses.get_or_add(relation, [])
	for lens in related_lenses:
		lens.consider(source)
func entity_get_component(entity: PECSEntityMarker, component: Script) -> Variant:
	return component_store[component][entity.component_handles[component]]
func entity_mark_component_updated(entity: PECSEntityMarker, component: Script) -> void:
	for fx: PECSSideEffect in entity.side_effects:
		var reacts = fx.listening_for_update.get(component, false)
		if reacts:
			fx.run(entity, component, component_store[component][entity.component_handles[component]])
	entity.mutated.emit(component)

func _relevant_lens_add(lens: Lens, component: Script):
	var arr: Array = relevant_lenses.get_or_add(component, [])
	arr.append(lens)
func hard_refresh_lens_cache():
	relevant_lenses.clear()
	for lens in maintained_lenses:
		for c in lens.filter_needs:
			_relevant_lens_add(lens, c)
		for c in lens.filter_without:
			_relevant_lens_add(lens, c)
		for c in lens.filter_with_relationship:
			_relevant_lens_add(lens, c)
func refresh_lens(lens: Lens):
	lens.list.clear()
	for e in entities:
		lens.consider(e)
	lens.dirty_lens = false



func _sort_systems(l: PECSSystem, r: PECSSystem) -> bool:
	if l.priority == r.priority:
		return l._internal_index < r._internal_index
	return l.priority > r.priority
func _sort_observers(l: PECSObserver, r: PECSObserver) -> bool:
	if l.priority == r.priority:
		return l._internal_index < r._internal_index
	return l.priority > r.priority

func get_partition(partition_script: Script) -> PECSPartition:
	for p in partitions:
		if p.get_script() == partition_script:
			return p
	return null

func find_entity_by_component(type: Script) -> PECSEntityMarker:
	if component_store.has(type):
		var array: Array = component_store[type]
		if !array.is_empty():
			if len(array) > 1:
				note.warn("Filtering entity by type returned multiple entities when this method is intended for singleton style entities. Prefer using a lens.")
			var component = array[0] as PECSComponent
			if component != null:
				return component.component_entity
	return null

func find_system_by_type(type: Script) -> PECSSystem:
	for sys in systems:
		if is_instance_of(sys, type):
			return sys
	return null
func find_observer_by_type(type: Script) -> PECSObserver:
	for obs in observers:
		if is_instance_of(obs, type):
			return obs
	return null

func partition_add_via_script(partition: Script) -> void:
	var instance = Node.new()
	instance.set_script(partition)
	if instance is PECSPartition:
		partition_add_via_node(instance)
func partition_add_via_node(node: PECSPartition) -> void:
	partitions.append(node)

func observer_add_via_script(observer: Script) -> void:
	var instance = Node.new()
	instance.set_script(observer)
	if instance is PECSObserver:
		observer_add_via_node(instance)

func observer_add_via_node(observer: PECSObserver) -> void:
	observer._internal_index = len(observers)
	observers.append(observer)
	observers.sort_custom(_sort_observers)
	if observer.event_bubble_behaviour == 0:
		_deferred_observers.append(observer)
	else:
		_immediate_observers.append(observer)
	if _began:
		observer.setup(self)

func observer_remove_via_node(observer: PECSObserver) -> void:
	_deferred_observers.erase(observer)
	_immediate_observers.erase(observer)
	observers.erase(observer)

func observer_remove_via_script(observer: Script) -> void:
	for s in observers:
		if s.get_script() == observer:
			observer_remove_via_node(s)
			break

func system_add_via_script(system: Script) -> void:
	var instance = Node.new()
	instance.set_script(system)
	if instance is PECSSystem:
		system_add_via_node(instance)

func system_add_via_node(system: PECSSystem) -> void:
	system._internal_index = len(observers)
	systems.append(system)
	systems.sort_custom(_sort_systems)
	if _began:
		system.setup(self)

func system_remove_via_node(system: PECSSystem) -> void:
	systems.erase(system)

func system_remove_via_script(system: Script) -> void:
	for s in systems:
		if is_instance_of(s, system):
			system_remove_via_node(s)
			break

func get_default_root() -> Node:
	return root_nodes[default_root]

## Creates and maintains a lens which lets you filter and look for
## entities dynamically. The entity list is refreshed for the first time
## on an ECS run tick, after which all changes to entities will be reflected
## in real time.
func create_lens() -> Lens:
	var l = Lens.new()
	maintained_lenses.append(l)
	return l

## Main access to tick the ECS system. This is done for you
## if you set auto run.
func run_ecs(delta: float):
	var refresh_required: bool = false
	for lens in maintained_lenses:
		if lens.dirty_lens:
			refresh_lens(lens)
			refresh_required = true
	if refresh_required:
		hard_refresh_lens_cache()
	_in_run = true
	for sys in systems:
		sys.run(delta)
	_in_run = false
	_flush_deferred_events()

func _flush_deferred_events():
	while len(_queued_events) > 0:
		var evt = _queued_events.pop_front()
		var dat = _queued_event_values.pop_front()
		for observer in _deferred_observers:
			if observer.is_interested_in(evt):
				observer.run(evt, dat)

## Raises an event to every observer, immediately for immediate observers,
## And after every system is done for deferred observers.
func raise_event(event, value = null):
	if !_in_run:
		for o in observers:
			if o.is_interested_in(event):
				o.run(event, value)
		return
	for o in _immediate_observers:
		if o.is_interested_in(event):
			o.run(event, value)
	_queued_events.append(event)
	_queued_event_values.append(value)

func _physics_process(delta: float) -> void:
	if !Engine.is_editor_hint() and auto_run == 1:
		run_ecs(delta)
func _process(delta: float) -> void:
	if !Engine.is_editor_hint() and auto_run == 2:
		run_ecs(delta)

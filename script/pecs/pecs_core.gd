@tool
extends Node
class_name PECSCore

const CORE_METATAG = &"__pecs_core_meta_marker"

class Lens extends RefCounted:
	var filter_needs: Array[Script] = []
	var filter_without: Array[Script] = []
	var filter_with_relationship: Array[Script] = []
	var dirty_lens: bool = true
	var list: Array[PECSEntityMarker] = []
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
			list.erase(ent)
		if !already_listening and is_valid:
			list.append(ent)
	func get_entities() -> Array[PECSEntityMarker]:
		## TODO, checks for dirty looker.
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

@export var domain: Node :
	set(val):
		domain = val
		update_configuration_warnings()
@export var preload_components: Array[Script] = []
@export_enum("None:0", "On Physics:1", "On Process:2") var auto_run: int = 0

var component_store: Dictionary[Script,Array] = {}
var systems: Array[PECSSystem] = []
var observers: Array[PECSObserver] = []

var entities: Array[PECSEntityMarker] = []
var entity_index: Dictionary[PECSEntityMarker, int]

var _update_pairs: Array = []
var _component_holes: Dictionary[Script,Array] = {}
var _queued_events: Array = []

var maintained_lenses: Array[Lens]
var relevant_lenses: Dictionary[Script, Array] = {}
var _immediate_observers: Array[PECSObserver]
var _deferred_observers: Array[PECSObserver]


func _get_configuration_warnings() -> PackedStringArray:
	var warns = []
	if domain == null:
		warns.append("Domain is a required parameter to function.") 
	if process_priority >= 0:
		warns.append("Physics and Regular Process priority should be <0 so this runs before your entities.")
	return warns

func _set(property: StringName, value: Variant) -> bool:
	if property == &"process_priority" or property == &"process_physics_priority":
		update_configuration_warnings()
	return false

func _enter_tree() -> void:
	if Engine.is_editor_hint(): return
	domain.set_meta(CORE_METATAG, self)
	for i in preload_components:
		component_add(i)
	for i in get_children():
		if i is PECSSystem:
			system_add_via_node(i)
		if i is PECSObserver:
			observer_add_via_node(i)

func instantiate_packed_scene(scene: PackedScene, to_parent: Node) -> PECSEntityMarker:
	var inst = scene.instantiate()
	for c in inst.get_children():
		if c is PECSEntityMarker:
			c._hook_into_core(self)
			c.is_setup_complete = true
			to_parent.call_deferred("add_child",inst)
			return c
	return null

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
	entities.append(ent)
	entity_index[ent] = ind
	var true_node = ent.get_parent()
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
	_update_pairs.append([entity, component])

func entity_remove_component(entity: PECSEntityMarker, component: Script) -> void:
	var ind = entity.component_handles[component]
	component_store[component][ind] = null
	_component_holes[component].append(ind)
	entity.component_handles.erase(component)
	var related_lenses = relevant_lenses.get_or_add(component, [])
	for lens in related_lenses:
		lens.consider(entity)
func entity_bond(source: PECSEntityMarker, relation: Script, target: PECSEntityMarker, value):
	var ent_array: Array = source.relationships.get_or_add(relation, [])
	var new_data = PECSEntityMarker.RelationshipData.new()
	new_data.target = target
	new_data.data = value
	ent_array.append(new_data)
	
	var related_lenses = relevant_lenses.get_or_add(relation, [])
	for lens in related_lenses:
		lens.consider(source)
func entity_unbond(source: PECSEntityMarker, relation: Script, target: PECSEntityMarker):
	var arr: Array = source.relationships.get_or_add(relation)
	var ind = arr.find_custom(func(item):
		return item.target == target
	)
	if ind != -1:
		arr.remove_at(ind)
		var related_lenses = relevant_lenses.get_or_add(relation, [])
		for lens in related_lenses:
			lens.consider(source)
func entity_get_component(entity: PECSEntityMarker, component: Script) -> Variant:
	return component_store[component][entity.component_handles[component]]
func entity_mark_component_updated(entity: PECSEntityMarker, component: Script, new_value) -> void:
	_update_pairs.append([entity, component])
	if new_value != null:
		component_store[component][entity.component_handles[component]] = new_value


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
	return l.priority > r.priority
func _sort_observers(l: PECSObserver, r: PECSObserver) -> bool:
	return l.priority > r.priority

func observer_add_via_script(observer: Script) -> void:
	var instance = Node.new()
	instance.set_script(observer)
	if instance is PECSObserver:
		observer_add_via_node(instance)
func observer_add_via_node(observer: PECSObserver) -> void:
	observer.setup(self)
	observers.append(observer)
	observers.sort_custom(_sort_observers)
	if observer.event_bubble_behaviour == 0:
		_deferred_observers.append(observer)
	else:
		_immediate_observers.append(observer)
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
	system.setup(self)
	systems.append(system)
	systems.sort_custom(_sort_systems)
func system_remove_via_node(system: PECSSystem) -> void:
	systems.erase(system)
func system_remove_via_script(system: Script) -> void:
	for s in systems:
		if s.get_script() == system:
			system_remove_via_node(s)
			break

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
	_queued_events.clear()
	var refresh_required: bool = false
	for lens in maintained_lenses:
		if lens.dirty_lens:
			refresh_lens(lens)
			refresh_required = true
	if refresh_required:
		hard_refresh_lens_cache()
	for sys in systems:
		sys.run(delta)
	for pair in _update_pairs:
		var ent = pair[0] as PECSEntityMarker
		var component = pair[1] as Script
		for fx: PECSSideEffect in ent.side_effects:
			var reacts = fx.listening_for_update.get(component, false)
			if reacts:
				fx.run(ent, component, component_store[component][ent.component_handles[component]])
	_update_pairs.clear()
	for event in _queued_events:
		for observer in _deferred_observers:
			if observer.is_interested_in(event):
				observer.run(event)

## Raises an event to every observer, immediately for immediate observers,
## And after every system is done for deferred observers.
func raise_event(event):
	for o in _immediate_observers:
		if o.is_interested_in(event):
			o.run(event)
	_queued_events.append(event)

func _physics_process(delta: float) -> void:
	if !Engine.is_editor_hint() and auto_run == 1:
		run_ecs(delta)
func _process(delta: float) -> void:
	if !Engine.is_editor_hint() and auto_run == 2:
		run_ecs(delta)

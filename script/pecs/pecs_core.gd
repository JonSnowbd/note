@tool
extends Node
class_name PECSCore

const CORE_METATAG = &"__pecs_core_meta_marker"

@export var domain: Node :
	set(val):
		domain = val
		update_configuration_warnings()
@export var preload_components: Array[Script] = []
@export_enum("None:0", "On Physics:1", "On Process:2") var auto_run: int = 0

var component_store: Dictionary[Script,Array] = {}
var systems: Array[PECSSystem] = []

var entities: Array[PECSEntityMarker] = []
var entity_index: Dictionary[PECSEntityMarker, int]

var looker: PECSSystem.Looker

var _update_pairs: Array = []
var _component_holes: Dictionary[Script,Array] = {}

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
	looker = PECSSystem.Looker.new()
	domain.set_meta(CORE_METATAG, self)
	for i in preload_components:
		component_add(i)
	for i in get_children():
		if i is PECSSystem:
			system_add_via_node(i)
func _ready() -> void:
	if Engine.is_editor_hint(): return
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
	for s in systems:
		s.looker_instance.consider(ent)
func notify_lost_entity(ent: PECSEntityMarker):
	var ind = entity_index.get(ent, -1)
	if ind != -1:
		entities[ind] = null
	for s in systems:
		s.looker_instance.list.erase(ent)
	

func component_add(component: Script):
	if !component_store.has(component):
		component_store[component] = []
		_component_holes[component] = []

## Returns true if an entity has a component.
func entity_has_component(entity: PECSEntityMarker, component: Script) -> bool:
	return entity.component_handles.has(component)
## Reserves a spot in the component store 
func entity_add_component(entity: PECSEntityMarker, component: Script, value: Variant) -> void:
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
	for sys in systems:
		if sys.looker_instance.filter_needs.has(component) or sys.looker_instance.filter_without.has(component):
			sys.looker_instance.consider(entity)
	_update_pairs.append([entity, component])
func entity_remove_component(entity: PECSEntityMarker, component: Script) -> void:
	var ind = entity.component_handles[component]
	component_store[component][ind] = null
	_component_holes[component].append(ind)
	entity.component_handles.erase(component)
	for sys in systems:
		if sys.looker_instance.filter_needs.has(component) or sys.looker_instance.filter_without.has(component):
			sys.looker_instance.consider(entity)
	
func entity_get_component(entity: PECSEntityMarker, component: Script) -> Variant:
	return component_store[component][entity.component_handles[component]]
func entity_mark_component_updated(entity: PECSEntityMarker, component: Script, new_value) -> void:
	_update_pairs.append([entity, component])
	if new_value != null:
		component_store[component][entity.component_handles[component]] = new_value

func system_refresh_looker(system: PECSSystem):
	system.looker_instance.list.clear()
	for e in entities:
		system.looker_instance.consider(e)
	system.looker_instance.dirty_looker = false
func _sort_systems(l: PECSSystem, r: PECSSystem) -> bool:
	return l.priority > r.priority
func system_add_via_script(system: Script) -> void:
	var instance = Node.new()
	instance.set_script(system)
	if instance is PECSSystem:
		instance.looker_instance = PECSSystem.Looker.new()
		instance.setup(instance.looker_instance)
		systems.append(instance)
		systems.sort_custom(_sort_systems)
func system_add_via_node(system: PECSSystem) -> void:
	system.looker_instance = PECSSystem.Looker.new()
	system.setup(system.looker_instance)
	systems.append(system)
	systems.sort_custom(_sort_systems)
func system_remove_via_node(system: PECSSystem) -> void:
	systems.erase(system)
func system_remove_via_script(system: Script) -> void:
	for s in systems:
		if s.get_script() == system:
			systems.erase(s)
			break

func run_ecs(delta: float):
	var tagged: Array[PECSEntityMarker] = []
	for sys in systems:
		if sys.looker_instance.dirty_looker:
			system_refresh_looker(sys)
		sys.run(sys.looker_instance, delta)
		for i: PECSEntityMarker in sys.looker_instance.list:
			if len(i.frame_tags) > 0:
				tagged.append(i)
	for pair in _update_pairs:
		var ent = pair[0] as PECSEntityMarker
		var component = pair[1] as Script
		for fx: PECSSideEffect in ent.side_effects:
			var reacts = fx.listening_for_update.get(component, false)
			if reacts:
				fx.run(ent, component, component_store[component][ent.component_handles[component]])
	_update_pairs.clear()
	if len(tagged) >0:
		for ent in tagged:
			for sys in systems:
				sys.tagged_entity_process(ent, delta)
			ent.frame_tags.clear()

func _physics_process(delta: float) -> void:
	if !Engine.is_editor_hint() and auto_run == 1:
		run_ecs(delta)
func _process(delta: float) -> void:
	if !Engine.is_editor_hint() and auto_run == 2:
		run_ecs(delta)

@abstract
extends Node
class_name PECSPartition

var core: PECSCore
var internal_lens: PECSCore.Lens

func _initialize(internal_core: PECSCore):
	core = internal_core
	internal_lens = internal_core.create_lens()
	internal_lens.entity_added.connect(entity_introduced)
	internal_lens.entity_lost.connect(entity_removed)
	internal_lens.entity_mutated.connect(entity_mutated)
	configure(internal_lens)
	#core.refresh_lens(internal_lens)

@abstract
func configure(lens: PECSCore.Lens) -> void

func entity_introduced(entity: PECSEntityMarker) -> void: pass
func entity_removed(entity: PECSEntityMarker) -> void: pass
func entity_mutated(entity: PECSEntityMarker, component: Script) -> void: pass

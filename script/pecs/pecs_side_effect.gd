@abstract
extends Node
class_name PECSSideEffect

## Mini optimization for PECS. Extend this and then listen for updates to
## specific components, so you can take updates inside of PECS and apply side effects
## outside of it, such as jiggling sprites on damage, or flashing a sprite.

var listening_for_update: Dictionary[Script,bool] = {}

func listen_to(component: Script):
	listening_for_update[component] = true
func stop_listening_to(component: Script):
	listening_for_update[component] = false

@abstract
func setup(entity: PECSEntityMarker)

@abstract
func run(entity: PECSEntityMarker, component_type: Script, component_data: Variant)

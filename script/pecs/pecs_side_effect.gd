@abstract
extends Node
class_name PECSSideEffect

var listening_for_update: Dictionary[Script,bool] = {}

func listen_to(component: Script):
	listening_for_update[component] = true
func stop_listening_to(component: Script):
	listening_for_update[component] = false

@abstract
func setup(entity: PECSEntityMarker)

@abstract
func run(entity: PECSEntityMarker, component_type: Script, component_data: Variant)

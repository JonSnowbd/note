@abstract
extends Node
class_name PECSBundler

var bundle_ran: bool = false

@abstract
func execute(target: PECSEntityMarker)

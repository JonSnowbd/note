@abstract
@icon("res://addons/note/texture/icon/pecs/bundler.svg")
extends Node
class_name PECSBundler

var bundle_ran: bool = false

@abstract
func execute(target: PECSEntityMarker)

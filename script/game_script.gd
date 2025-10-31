extends RefCounted
class_name NoteGameScript

## A Game Script is a script thats not intended to exist as a node, Note can
## easily create and run these scripts with parameters. I use this method
## for things such as "Creation scripts", collections of scripts that can create
## things like levels, or players via script rather than resource management.

var tree: SceneTree

## VIRTUAL: If implemented and returns a real string this game script
## can be used via the Note dev console as a command.
func script_name() -> String:
	return ""

## VIRTUAL: If script_name is implemented, this is its help string.
func script_documentation() -> String:
	return ""

## VIRTUAL: This is ran when [code]note.execute[/code] is called with
## this script referenced.
func execute(param):
	pass

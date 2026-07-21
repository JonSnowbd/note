extends RefCounted
class_name Contract

## A Contract is a convenient data structure that has several clauses to check
## every frame, with a break function to call if any clause is invalidated.
## Very useful for things such as creation
## You do not [i]need[/i] to store this anywhere, on init this contract will upload to note
## for validation per process frame. Though you will need to keep a reference if you wish
## to cancel a contract.


## Emits when any clause is void during [code]Contract.update()[/code]
signal expired

@abstract
class Clause extends RefCounted:
	@abstract
	## Returns true if the clause still holds.
	func is_still_valid() -> bool

var is_valid: bool = true
var clauses: Array[Clause] = []

func update():
	if !is_valid:
		return
	for c in clauses:
		if c.is_still_valid():
			is_valid = false
			expired.emit()
			break

func add_clause(clause: Clause):
	clauses.append(clause)

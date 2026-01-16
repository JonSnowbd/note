extends RefCounted
class_name Contract


## A Contract is a convenient data structure that I typically use
## in phases, where the beginning of a phase, eg "InventoryPhase" receives a contract
## loaded with clauses that will notify the phase that its over, such as the
## Inventory Control being hidden/deleted, player taking damage, etc, and when
## the contract is expired, the phase will return to "PlayerControllerPhase".
## This structure has many uses, but this is one example.


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

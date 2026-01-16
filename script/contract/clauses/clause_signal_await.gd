extends Contract.Clause
class_name ClauseSignalAwait

## Returns true until a signal is emitted.

var has_triggered: bool = false
func trip(_1=false,_2=false,_3=false,_4=false,_5=false,_6=false,_7=false,_8=false,):
	has_triggered = true

func _init(target_signal: Signal) -> void:
	target_signal.connect(trip)
func is_still_valid() -> bool:
	return !has_triggered

@abstract
extends Node
class_name NoteTestFixture

signal test_succeeded
signal test_failed
signal test_over

@export var test_in_physics_process: bool

var test_running: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	test_running = true
	note.info("Beginning test fixture '%s'" % name, "TEST")
	test_ready()

func _run(delta: float):
	if test_running:
		test_process(delta)

func _process(delta: float) -> void:
	if !test_in_physics_process:
		_run(delta)
func _physics_process(delta: float) -> void:
	if test_in_physics_process:
		_run(delta)

func test_info(message: String):
	note.info("  ⤷ %s" % message, "TEST")
func test_warn(message: String):
	note.warn("  ⤷ %s" % message, "TEST")
func test_error(message: String):
	note.error("  ⤷ %s" % message)
func test_success():
	test_running = false
	test_info("Successful test.")
	test_succeeded.emit()
	test_over.emit()
func test_fail(fail_message: String = ""):
	test_running = false
	test_error(fail_message)
	test_failed.emit()
	test_over.emit()
@abstract
func test_ready()
@abstract
func test_process(delta: float)

extends NoteTestFixture

@export var core: PECSCore
@export var velocity_system: PECSSystem

const CPos = preload("uid://clj48uc0xy21n")
const SVel = preload("uid://fkbnrgpdrl0l")
const CVel = preload("uid://cajflpto7dpra")

var ent1: PECSEntityMarker
var ent2: PECSEntityMarker

func make_ent(pos: Vector2, vel: Vector2) -> PECSEntityMarker:
	var e = core.instantiate_blank_entity()
	var epos = CPos.new()
	epos.value = pos
	var evel = CVel.new()
	evel.value = vel
	e.add_component(CPos, epos)
	e.add_component(CVel, evel)
	return e

func test_ready():
	pass
func test_process(delta: float):
	if !test_running: return
	var physics = velocity_system as SVel
	if len(physics.entities.list) != 0:
		test_fail("Fake entities are in the list before addition.")
		return
	ent1 = make_ent(Vector2(-10.0, 0.0), Vector2(10.0, 0.0))
	ent1.name = "Entity#1"
	ent2 = make_ent(Vector2(10.0, 0.0), Vector2(-10.0, 0.0))
	ent2.name = "Entity#2"
	if !ent1.has_component(CPos):
		test_fail("Components are not immediately present on a new entity.")
		return
	if len(physics.entities.list) != 2:
		test_fail("Entities are not immediately reflected in system lenses.")
		return
	core.run_ecs(1.0)
	
	var e1p: CPos = ent1.get_component(CPos)
	if !is_equal_approx(e1p.value.x, 0.0):
		test_fail("Delta incorrectly supplied, or system mutations are late. Found %.1f expected %.1f" % [e1p.value.x, 0.0])
		return
	
	test_success()

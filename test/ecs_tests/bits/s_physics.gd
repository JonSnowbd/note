extends PECSSystem

const CPos = preload("uid://clj48uc0xy21n")
const CVel = preload("uid://cajflpto7dpra")

var entities: PECSCore.Lens

func setup(core: PECSCore):
	entities = core.create_lens()
	entities.setup_with([])

func run(delta: float):
	for e in entities.get_entities():
		var pos: CPos = e.get_component(CPos)
		var vel: CVel = e.get_component(CVel)
		pos.value += (vel.value*delta)

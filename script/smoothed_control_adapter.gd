extends Node2D
class_name SmoothedControlAdapter2D

enum ApproachType {
	Linear,
	Smooth,
	SemiLinear
}

## Smooth-to will only work when an anchor id disappears, and then re-appears with the same id.
## Use this identity the way you would a key in react listviews.
@export var anchor: String = ""
@export var approach_type: ApproachType = ApproachType.Linear
@export var approach_speed: float = 400.0

@export var nudge_translation:Vector2 = Vector2.ZERO
@export var nudge_rotation: float = 0.0

extends Area2D
class_name NoteCameraAffector

@export_category("Biases")
## If assigned, the camera will bias towards the closest point on the track
@export var track_bias: Path2D
@export var track_bias_strength: float = 0.0
## The camera will bias towards the center of all the nodes, scaled by the bias strength.
@export var node_biases: Array[Node2D]
@export var node_bias_strength: float = 0.0

func get_offset(origin_world_point: Vector2) -> Vector2:
	var offset = Vector2.ZERO
	if track_bias != null and track_bias_strength != 0.0:
		var closest_point = track_bias.to_global(track_bias.curve.get_closest_point(track_bias.to_local(origin_world_point)))
		offset += (origin_world_point - closest_point) * track_bias_strength
	
	if len(node_biases) > 0 and node_bias_strength != 0.0:
		var center = Vector2.ZERO
		for node in node_biases:
			center += node.global_position
		center /= len(node_biases)
		offset += (origin_world_point - center) * node_bias_strength
	return offset

## One patch of an Inferred Boundary: a rectangle of surface fitted to the points
## of Navigation's point cloud that seem to lie on it. Plain data; BoundaryFit
## makes these, views read them.
class_name BoundaryPatch
extends RefCounted

## The middle of the patch, in metres in the world frame (as
## ScanPoint.position): origin where the dive began, +Y up.
var centre: Vector3
## Which way the surface faces: a unit vector, never pointing down.
var normal: Vector3
## The ground it covers, metres: its extent along x and along z, the span of
## the points it was fitted to.
var size: Vector2
## How many points it was fitted to.
var support: int
## How sure the fit is that a Boundary lies here, 0 to 1: higher the more
## points support it and the more confident they are.
var confidence: float
## When its points returned, on average, in seconds of the dive
## (ScanPoint.returned_at), so it fades with them. The simulation's
## patch_age() reads its age.
var returned_at: float


func _init(p_centre: Vector3, p_normal: Vector3, p_size: Vector2, p_support: int,
		p_confidence: float, p_returned_at: float) -> void:
	centre = p_centre
	normal = p_normal
	size = p_size
	support = p_support
	confidence = p_confidence
	returned_at = p_returned_at


## The patch's four corners on its surface, in the world frame, going round:
## the rectangle of ground it covers, lifted onto the fitted plane.
func corners() -> Array[Vector3]:
	var half := size * 0.5
	var found: Array[Vector3] = []
	for offset in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half,
			Vector2(-half.x, half.y)]:
		found.append(centre + Vector3(offset.x, _rise(offset), offset.y))
	return found


## How far the surface rises above the centre's height at this offset across
## the ground (x, z), in metres.
func _rise(offset: Vector2) -> float:
	return -(normal.x * offset.x + normal.z * offset.y) / normal.y

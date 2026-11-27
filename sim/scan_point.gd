## One point in Navigation's point cloud: where an echo of a pulse seemed to
## come from, and how sure the scan is of it. Plain data; the simulation makes
## these, views read them.
class_name ScanPoint
extends RefCounted

## Where the echo seemed to come from, in metres in the world frame
## (DiveSimulation.head_position()): origin where the dive began, +Y up, so a
## point at depth d has y = -d. Uncertain points are scattered off the true
## echo, more so the less confident they are.
var position: Vector3
## How sure the scan is of the point, 0 (a guess) to 1 (certain). Falls with
## range and with the vessel's own noise when the pulse was sent.
var confidence: float
## Distance from the Head to the echo when the pulse was sent, in metres.
var range: float
## Which pulse found it: 0 for the dive's first pulse, counting up; -1 for
## surface control's survey, which no pulse of the vessel's found.
var pulse: int
## When its echo returned, in seconds of the dive (DiveSimulation.dive_time()).
## Its age is DiveSimulation.point_age().
var returned_at: float
## True for a point of surface control's survey, in the scan as the dive
## began (DiveSimulation.start_surveyed()); false for the vessel's own echoes.
var surveyed := false


func _init(p_position: Vector3, p_confidence: float, p_range: float, p_pulse: int,
		p_returned_at: float, p_surveyed := false) -> void:
	position = p_position
	confidence = p_confidence
	range = p_range
	pulse = p_pulse
	returned_at = p_returned_at
	surveyed = p_surveyed

## The Drive's attitude ball (FlightDisplay): a sphere fixed to the world,
## marked in pitch and compass heading, seen from inside the vessel along
## where the Head points, so the Head's direction is always the ball's middle
## and every other direction lies on the ball where it lies from the Head.
##
## The face is turned so the way toward the surface along the Head's own
## meridian is up, and the heading the Head has (heading_degrees(), the last
## one while vertical) runs through the middle top to bottom. That holds at
## every pitch, straight up and down included, so the ball has no dead spot:
## straight down, the rock's pole is the middle and the Head's heading points
## up from it; tilted toward a heading, the pole slides down that meridian.
##
## Plain data, no drawing: places on the unit disc, x to the right and y down
## the screen (the orthographic picture of the half of the ball that faces the
## crew), which FlightDisplay scales by the ball's radius.
class_name AttitudeBall
extends RefCounted

## The Head's pitch and heading, degrees (the simulation's: + diving).
var pitch: float
var heading: float

# The face's basis in the world's (north, east, down) frame: toward the crew
# (where the Head points), the screen's right, and the screen's up.
var _toward := Vector3.ZERO
var _right := Vector3.ZERO
var _up := Vector3.ZERO


func _init(p_pitch: float, p_heading: float) -> void:
	pitch = p_pitch
	heading = p_heading
	var p := deg_to_rad(pitch)
	var h := deg_to_rad(heading)
	var ahead := Vector3(cos(h), sin(h), 0.0)
	var down := Vector3(0.0, 0.0, 1.0)
	_toward = cos(p) * ahead + sin(p) * down
	_right = Vector3(-sin(h), cos(h), 0.0)
	_up = sin(p) * ahead - cos(p) * down


## A direction at a compass heading and pitch, degrees, as a unit vector in
## the world's (north, east, down) frame.
static func direction(at_heading: float, at_pitch: float) -> Vector3:
	var h := deg_to_rad(at_heading)
	var p := deg_to_rad(at_pitch)
	return Vector3(cos(p) * cos(h), cos(p) * sin(h), sin(p))


## Where a direction lies against the face: x to the right, y up the screen,
## z toward the crew (1 at the middle, 0 at the rim, below 0 behind the ball).
func facing(at_heading: float, at_pitch: float) -> Vector3:
	var d := direction(at_heading, at_pitch)
	return Vector3(d.dot(_right), d.dot(_up), d.dot(_toward))


## Whether a direction is on the half of the ball that faces the crew.
func on_face(at_heading: float, at_pitch: float) -> bool:
	return facing(at_heading, at_pitch).z >= 0.0


## Where a direction is drawn on the unit disc (x right, y down): at its place
## on the face, or, behind the ball, pinned to the rim on its side, so a mark
## always shows which way to turn. Straight behind, it is pinned to the foot.
func place(at_heading: float, at_pitch: float) -> Vector2:
	var f := facing(at_heading, at_pitch)
	var flat := Vector2(f.x, -f.y)
	if f.z >= 0.0:
		return flat
	return flat.normalized() if flat.length() > 0.0001 else Vector2(0.0, 1.0)


## The outline of the ball's surfaceward part on the unit disc (x right, y
## down): the horizon's half ellipse through the rim's left and right, then
## the rim over the top. Empty when the surface shows only as a sliver
## (straight down), and the whole rim when the rock does (straight up).
func surfaceward(samples: int = 48) -> PackedVector2Array:
	var rise := sin(deg_to_rad(pitch))
	var outline := PackedVector2Array()
	if rise > 0.98:
		return outline
	if rise < -0.98:
		for i in samples * 2:
			var t := TAU * i / (samples * 2)
			outline.append(Vector2(cos(t), sin(t)))
		return outline
	for i in samples + 1:
		var x := -1.0 + 2.0 * i / samples
		outline.append(Vector2(x, -rise * sqrt(maxf(0.0, 1.0 - x * x))))
	for i in range(1, samples):
		var t := PI * i / samples
		outline.append(Vector2(cos(t), -sin(t)))
	return outline


## The visible runs of the circle of a pitch (a parallel), each a polyline on
## the unit disc.
func parallel(at_pitch: float, samples: int = 72) -> Array[PackedVector2Array]:
	var points: Array[Vector3] = []
	for i in samples + 1:
		points.append(facing(heading + 360.0 * i / samples, at_pitch))
	return _runs(points)


## The visible runs of the half circle of a compass heading from pole to pole
## (a meridian), each a polyline on the unit disc.
func meridian(at_heading: float, samples: int = 36) -> Array[PackedVector2Array]:
	var points: Array[Vector3] = []
	for i in samples + 1:
		points.append(facing(at_heading, -90.0 + 180.0 * i / samples))
	return _runs(points)


## The runs of points on the face, each as places on the unit disc.
static func _runs(points: Array[Vector3]) -> Array[PackedVector2Array]:
	var runs: Array[PackedVector2Array] = []
	var run := PackedVector2Array()
	for f in points:
		if f.z >= 0.0:
			run.append(Vector2(f.x, -f.y))
		elif run.size() > 0:
			if run.size() > 1:
				runs.append(run)
			run = PackedVector2Array()
	if run.size() > 1:
		runs.append(run)
	return runs

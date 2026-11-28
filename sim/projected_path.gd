## The turning rule, and the projected path: that rule run forward.
##
## The Head turns the Lithocraft by heating one side of its rim harder than
## the other, so the vessel cuts faster on that side and its path bends. The
## turning rule (turned()) is one step of that, and it is the one both a
## step of the simulation and the projected path (ahead()) run, so the
## projection can never disagree with how the vessel turns.
##
## Everything here is a plain function of what it is handed: a Head partway
## through a turn (Turning), the direction the Drive steers for, its steering
## effort and the vessel's speed. It keeps no state and knows nothing of the
## layout, the Media, the Stations or the rock ahead, so a change of Medium,
## power or setting bends the real path away from the projected one.
##
## Owned by the simulation, which answers for it (a subsystem: see
## docs/conventions/simulation-interface.md).
class_name ProjectedPath
extends RefCounted

## The tightest arc the Lithocraft can cut, in metres of radius. Tuned for
## play (ADR 0001); tests read DiveSimulation.minimum_turn_radius(), never
## this. 60 m since #161 (250 m before): a turn for home a few hundred metres
## across, not a kilometre.
const _MIN_TURN_RADIUS_M := 60.0
## How fast the uneven heating builds up or dies away, as a share of full
## steering per second: the vessel answers the Drive slowly. Tuned for play.
const _STEER_RESPONSE := 0.1
## Within this many degrees of the setting the steering eases off, so the
## vessel settles onto its heading instead of swinging past. Tuned for play.
const _STEER_EASE_DEG := 10.0
## The projected path (ahead()): its points lie this far apart along a turn,
## metres, whatever the speed, so the work of projecting does not grow as the
## vessel slows (the turning rule cuts the same arc in long steps as in
## short); how far the straight stretch beyond the turn reaches, metres; and
## the most path a turn is followed for, metres, so a Drive barely steering
## does not project for ever. Tuned for play (ADR 0001). Checked against the
## 60 m tightest turn (#161): a 5 m piece is under 5 degrees of its arc, a few
## centimetres off it, and 4000 m follows a quarter turn steered at a fortieth
## of full effort.
const _SAMPLE_M := 5.0
const _STRAIGHT_M := 250.0
const _TURN_M := 4000.0
## The turn is over, for the projection, once the Head points within this
## many degrees of what the Drive steers for: the steering eases off as it
## nears, so the last of a turn is all but straight.
const _SETTLED_DEG := 0.05


## A Head partway through a turn: where it is (world frame), the way it
## points, its last compass bearing in degrees and how hard it steers, 0 to 1.
## What the turning rule (turned()) steps from and gives back.
class Turning:
	extends RefCounted
	var position: Vector3
	var direction: Vector3
	var bearing: float
	var steering: float

	func _init(p_position: Vector3, p_direction: Vector3, p_bearing: float, p_steering: float) -> void:
		position = p_position
		direction = p_direction
		bearing = p_bearing
		steering = p_steering


## Radius in metres of the tightest arc the turning rule cuts.
static func minimum_turn_radius() -> float:
	return _MIN_TURN_RADIUS_M


## The path a Head at `from` follows if nothing changes, as points in the
## world frame joined by straight pieces. The first is where it is now; the
## rest run through the turn toward `wanted` (a unit vector), steering no
## harder than `effort`, each no more than a few metres of path from the
## last, and end with one straight stretch beyond the turn. `speed_steering`
## gives the vessel's speed, metres a second, for a steering of 0 to 1
## (steering harder may leave less power to push with); the path ends where
## it gives none. A climb is projected no further than the surface (y = 0),
## and a turn too wide to finish is cut short without its straight stretch.
## With no steering at all the vessel never comes round, so the path is one
## straight stretch the way the Head points.
static func ahead(from: Turning, wanted: Vector3, effort: float,
		speed_steering: Callable) -> PackedVector3Array:
	var path := PackedVector3Array([from.position])
	var settled := deg_to_rad(_SETTLED_DEG)
	var turning := from
	var since_point := 0.0
	var length := 0.0
	var straight_on := false
	while turning.direction.angle_to(wanted) > settled and length < _TURN_M:
		var speed: float = speed_steering.call(turning.steering)
		if speed <= 0.0:
			break
		var dt := _SAMPLE_M / speed
		var before := turning.position
		var pointed := turning.direction
		turning = turned(turning, wanted, effort, speed, dt)
		# No steering and none building: the vessel goes straight on and never
		# comes round, so the rest of the path is the way it points.
		if turning.steering <= 0.0 and turning.direction.is_equal_approx(pointed):
			straight_on = true
			break
		length += speed * dt
		since_point += speed * dt
		if _surfaces_between(before, turning.position):
			path.append(_at_the_surface(before, turning.position))
			return path
		if since_point >= _SAMPLE_M:
			since_point = 0.0
			path.append(turning.position)
	var end_of_turn := turning.position
	if since_point > 0.0:
		path.append(end_of_turn)
	var onward := turning.direction if straight_on else wanted
	if not straight_on and turning.direction.angle_to(wanted) > settled:
		return path
	var end := end_of_turn + onward * _STRAIGHT_M
	path.append(_at_the_surface(end_of_turn, end) if _surfaces_between(end_of_turn, end) else end)
	return path


## The turning rule, the one both a step of the simulation and the projected
## path (ahead()) run: the Head as `from` has it turns toward `wanted` for dt
## seconds at this speed and moves along the arc. Returns the Head
## afterwards, a new Turning. The steering builds toward what
## the remaining turn needs, no harder than `effort`, at a limited rate, and
## the path bends by at most speed / minimum radius radians per second, so a
## stopped vessel cannot turn and none turns tighter than its minimum arc. The
## Head only ever moves the way it points.
static func turned(from: Turning, wanted: Vector3, effort: float, speed: float,
		dt: float) -> Turning:
	var position := from.position
	var direction := from.direction
	var bearing := from.bearing
	var steering := from.steering
	var remaining := direction.angle_to(wanted)
	var needed := clampf(rad_to_deg(remaining) / _STEER_EASE_DEG, 0.0, effort)
	# The path bends by the steering's mean over the step (it builds at its
	# limited rate, then holds), so a long step and many short ones cut the
	# same arc.
	var building := minf(absf(needed - steering) / _STEER_RESPONSE, dt)
	var built := move_toward(steering, needed, _STEER_RESPONSE * dt)
	var mean := built if dt <= 0.0 else built - (built - steering) * building / (2.0 * dt)
	steering = built
	var turn := minf(remaining, mean * speed / _MIN_TURN_RADIUS_M * dt)
	var before := direction
	if turn > 0.0:
		if turn >= remaining:
			direction = wanted
		else:
			direction = direction.rotated(_turn_axis(direction, wanted, bearing), turn).normalized()
	# Along the arc: the chord points halfway between the two directions and
	# is a little shorter than the arc.
	var travelled := speed * dt
	if turn > 1e-9:
		var chord := 2.0 * sin(turn / 2.0) / turn
		position += (before + direction).normalized() * travelled * chord
	else:
		position += direction * travelled
	if Vector2(direction.x, direction.z).length() > 1e-4:
		bearing = fposmod(rad_to_deg(atan2(direction.x, -direction.z)), 360.0)
	return Turning.new(position, direction, bearing, steering)


## The axis to turn about to bring a Head pointing along `direction` round
## toward wanted. A straight about-turn goes round sideways when the Head is
## not vertical, and over the bearing when it points straight up or down.
static func _turn_axis(direction: Vector3, wanted: Vector3, bearing: float) -> Vector3:
	var axis := direction.cross(wanted)
	if axis.length() > 1e-6:
		return axis.normalized()
	var sideways := Vector3.UP - direction * direction.dot(Vector3.UP)
	if sideways.length() > 1e-4:
		return sideways.normalized()
	var h := deg_to_rad(bearing)
	return Vector3(cos(h), 0.0, sin(h)) * signf(-direction.y)


## True when the straight piece from one place to another comes up through
## the surface.
static func _surfaces_between(from: Vector3, to: Vector3) -> bool:
	return from.y < 0.0 and to.y >= 0.0


## Where the straight piece from one place to another meets the surface.
static func _at_the_surface(from: Vector3, to: Vector3) -> Vector3:
	return from.lerp(to, -from.y / (to.y - from.y))

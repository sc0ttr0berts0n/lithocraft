## The Arm: a carriage on a rail round the Bore with a chain-arm and a claw.
## The rail itself slides along the Bore: it keeps level with the ring of
## Stations (slide_to()), and pressed once it first runs along the Bore to the
## crew member wherever they are along its length, then reaches out, catches
## them by the harness between their shoulders and carries them to the
## nearest Station, the rail running back to the ring with them; left and
## right carry them on to the next Station that side; pressed again it lets
## go. Works whatever "down" is, because it is told only where the crew
## member's eyes are and where each Station is worked from.
##
## Plain data in the Habitat frame, no scene: the Habitat steps it and draws
## it, and holds the crew member where held_eye() says while is_holding().
## The feel and geometry come from the browser prototype on
## prototype/habitat-down; the timings are tuned for play.
class_name Arm
extends RefCounted

enum State { PARKED, REACHING, HOLDING, RETURNING }

## Seconds to reach out and catch once the rail is level with the crew
## member, and to swing back to the rail.
const REACH_TIME := 0.9
const RETURN_TIME := 0.6
## Carrying speed, metres of path per second.
const CARRY_SPEED := 1.6
## How fast the carriage runs round the rail, radians per second.
const RAIL_SPEED := 4.0
## How fast the rail runs along the Bore, metres per second: faster than the
## ring of Stations ever slides, so it keeps up with them.
const RUN_SPEED := 4.0
## The rail counts as level with the crew member within this, metres.
const LEVEL_WITH := 0.02
## Where the harness is from the eyes: down the back and behind.
const HARNESS_BELOW_EYES := 0.45
const HARNESS_BEHIND := 0.3
## How far the claw hangs out from the carriage when parked.
const PARKED_REACH := 0.3
## Links drawn between the carriage and the claw.
const CHAIN_LINKS := 18
## Metres: two neighbours closer than this to the same side count as level.
const SIDE_TIE := 0.1

## The rail: its radius round the Bore's axis, its place along it now (z),
## where the ring of Stations is, which it keeps level with unless it is
## away fetching the crew member, and the ends of its run along the Bore.
var _rail_radius: float
var _rail_z: float
var _ring_z: float
var _run_from: float
var _run_to: float
var _state := State.PARKED
var _rail_angle := -PI / 2.0
var _t := 0.0
var _hand := Vector3.ZERO
var _hand_from := Vector3.ZERO
## The crew member's eyes as last seen (Habitat frame).
var _body := Transform3D.IDENTITY
## Carry: from where, to which Station, how far along (0..1).
var _from := Transform3D.IDENTITY
var _to := -1
var _u := 1.0
var _held := Transform3D.IDENTITY
## A left (-1) or right (+1) asked for, taken on the next step, which has
## the Stations.
var _shift := 0
## The last left or right taken, the Station it left, and which way round
## the ring it went (+1 up the list, -1 down it). Forgotten on letting go.
var _last_side := 0
var _came_from := -1
var _last_round := 0


## rail_z: where the ring of Stations is, and the rail with it, to begin
## with. run_from, run_to: how far along the Bore the rail can run (z).
func _init(rail_radius: float, rail_z := 0.0, run_from := -INF, run_to := INF) -> void:
	_rail_radius = rail_radius
	_rail_z = rail_z
	_ring_z = rail_z
	_run_from = run_from
	_run_to = run_to
	_hand = _parked_hand()


# --- Commands -------------------------------------------------------------

## The Arm's one button: call it if it is away, let go if it has you.
func press() -> void:
	if _state == State.PARKED or _state == State.RETURNING:
		_state = State.REACHING
	else:
		_state = State.RETURNING
	_shift = 0
	_last_side = 0
	_came_from = -1
	_t = 0.0
	_hand_from = _hand


## The ring of Stations is here along the Bore now (z): the rail keeps level
## with it, sliding as it slides, except while it is away fetching the crew
## member. Told every step the ring may have moved.
func slide_to(ring_z: float) -> void:
	_ring_z = ring_z


## Carry on to the next Station on the crew member's right (side > 0) or
## left (side < 0). Ignored unless holding.
func shift(side: int) -> void:
	if is_holding():
		_shift = signi(side)


## Holds the crew member seated at this Station at once, with no reach and no
## carry: `station` indexes the Stations step() is given, `pose` is where that
## one is worked from now. For a start already at a Station (the screenshot
## tool); left, right and the button work from there as after any carry.
func seat(station: int, pose: Transform3D) -> void:
	_state = State.HOLDING
	_to = station
	_from = pose
	_held = pose
	_body = pose
	_u = 1.0
	_hand = _harness(pose)
	_rail_angle = _angle_of(pose.origin)
	_rail_z = _ring_z
	_shift = 0
	_last_side = 0
	_came_from = -1


func _take_shift(stations: Array[Transform3D]) -> void:
	var count := stations.size()
	if _shift == 0 or count < 2:
		_shift = 0
		return
	var ahead := (_to + 1) % count
	var behind := (_to + count - 1) % count
	var pick: int
	if _shift == -_last_side and _came_from >= 0:
		# The other way from last time: back where they came from.
		pick = _came_from
	else:
		# Of the two neighbours round the ring, the one further toward that
		# side as the crew member sees it now (the prototype's rule).
		var eye := _held
		var toward := func(i: int) -> float:
			return (stations[i].origin - eye.origin).dot(eye.basis.x) * _shift
		var lead: float = toward.call(ahead) - toward.call(behind)
		if absf(lead) < SIDE_TIE:
			# Neither is clearly that side (both straight above and below,
			# say): keep going round the way the last press went, or on a
			# first press, right is up the list and left down it, so the
			# two keys never lead the same way.
			if _shift == _last_side:
				pick = ahead if _last_round > 0 else behind
			else:
				pick = ahead if _shift > 0 else behind
		else:
			pick = ahead if lead >= 0.0 else behind
	_came_from = _to
	_last_side = _shift
	_last_round = 1 if pick == ahead else -1
	_from = _held
	_to = pick
	_u = 0.0
	_shift = 0


# --- Time step ------------------------------------------------------------

## eye: the crew member's eyes now (ignored while held).
## stations: where each Station is worked from, as GimballedStation.pose().
func step(dt: float, eye: Transform3D, stations: Array[Transform3D]) -> void:
	match _state:
		State.REACHING:
			_body = eye
			_turn_carriage_toward(_angle_of(eye.origin), dt)
			# Along the Bore to the crew member first; the claw goes with the
			# rail, and reaches out only once it is level with them.
			if _run_rail_toward(eye.origin.z, dt) > LEVEL_WITH and _t <= 0.0:
				return
			_t = minf(1.0, _t + dt / REACH_TIME)
			var e := _ease(_t)
			# Swing round behind and above them on the way in, out of sight.
			var behind_above := (eye.basis.z + eye.basis.y).normalized()
			_hand = _hand_from.lerp(_harness(eye), e) + behind_above * sin(PI * _t) * 0.6
			if _t >= 1.0 and not stations.is_empty():
				_state = State.HOLDING
				_from = eye
				_held = eye
				_to = _nearest(eye.origin, stations)
				_u = 0.0
		State.HOLDING:
			_take_shift(stations)
			var to := stations[_to]
			_carry(dt, to)
			# The rail runs back to the ring as the crew member nears their
			# Station, and rides with the ring once they are there.
			_run_rail_toward(_ring_z + _held.origin.z - to.origin.z, dt)
			_body = _held
			_hand = _harness(_held)
		State.RETURNING:
			_run_rail_toward(_ring_z, dt)
			_t = minf(1.0, _t + dt / RETURN_TIME)
			_hand = _hand_from.lerp(_parked_hand(), _ease(_t))
			if _t >= 1.0:
				_state = State.PARKED
		_:
			_run_rail_toward(_ring_z, dt)
			_hand = _parked_hand()


# --- State out ------------------------------------------------------------

func state() -> State:
	return _state


## True while the Arm has the crew member, carrying or keeping them seated.
func is_holding() -> bool:
	return _state == State.HOLDING


## Where the crew member's eyes are held (Habitat frame). Meaningful while
## is_holding().
func held_eye() -> Transform3D:
	return _held


## The Station the Arm is carrying to or holding at, or -1.
func station() -> int:
	return _to if _state == State.HOLDING else -1


## Where along the Bore the rail is now (Habitat frame, z).
func rail_z() -> float:
	return _rail_z


## The carriage on the rail (Habitat frame).
func carriage() -> Vector3:
	return _rail_point()


## The claw (Habitat frame).
func hand() -> Vector3:
	return _hand


## True while the claw is closed on the harness.
func gripping() -> bool:
	return is_holding()


## Points along the chain from the carriage to the claw, both included.
## It leaves the carriage outward from the Bore and, while it reaches for or
## holds the crew member, comes in from behind and above them so it stays
## out of their view; otherwise it sags.
func chain(links := CHAIN_LINKS) -> PackedVector3Array:
	var c := _rail_point()
	var h := _hand
	var d := c.distance_to(h)
	var c1: Vector3
	var c2: Vector3
	if _state == State.HOLDING or _state == State.REACHING:
		# Up from the carriage first (the crew member's up), over anything
		# in front of them, then down onto the harness from behind.
		c1 = c + _body.basis.y * 0.5 * d
		c2 = h + _body.basis.z * (0.35 * d + 0.3) + _body.basis.y * 0.25 * d
	else:
		c1 = c + Vector3(c.x, c.y, 0).normalized() * 0.35 * d
		c2 = c.lerp(h, 0.5) - _body.basis.y * 0.25 * d
	var points := PackedVector3Array()
	for i in links + 2:
		var t := float(i) / (links + 1)
		var s := 1.0 - t
		points.append(c * s * s * s + c1 * 3.0 * s * s * t + c2 * 3.0 * s * t * t + h * t * t * t)
	return points


## True once a carry has reached its Station.
func arrived() -> bool:
	return is_holding() and _u >= 1.0


# --- Inside ---------------------------------------------------------------

func _carry(dt: float, to: Transform3D) -> void:
	var from_angle := _angle_of(_from.origin)
	var turn := wrapf(_angle_of(to.origin) - from_angle, -PI, PI)
	var from_r := _radius_of(_from.origin)
	var to_r := _radius_of(to.origin)
	var distance := absf(turn) * maxf(from_r, to_r) + absf(to_r - from_r) \
		+ absf(to.origin.z - _from.origin.z)
	_u = minf(1.0, _u + dt * CARRY_SPEED / maxf(0.3, distance))
	var e := _ease(_u)
	var angle := from_angle + turn * e
	var r := lerpf(from_r, to_r, e)
	var z := lerpf(_from.origin.z, to.origin.z, e)
	var turned := _from.basis.get_rotation_quaternion().slerp(to.basis.get_rotation_quaternion(), e)
	_held = Transform3D(Basis(turned), Vector3(cos(angle) * r, sin(angle) * r, z))
	_turn_carriage_toward(angle, dt)


func _nearest(point: Vector3, stations: Array[Transform3D]) -> int:
	var best := 0
	for i in stations.size():
		if point.distance_to(stations[i].origin) < point.distance_to(stations[best].origin):
			best = i
	return best


func _harness(eye: Transform3D) -> Vector3:
	return eye.origin - eye.basis.y * HARNESS_BELOW_EYES + eye.basis.z * HARNESS_BEHIND


func _rail_point() -> Vector3:
	return Vector3(cos(_rail_angle), sin(_rail_angle), 0) * _rail_radius + Vector3(0, 0, _rail_z)


func _parked_hand() -> Vector3:
	return _rail_point() + Vector3(cos(_rail_angle), sin(_rail_angle), 0) * PARKED_REACH


## Runs the rail along the Bore toward z, as far as its run goes, the claw
## going with it while it is not out on the harness. Returns how far it still
## is from where it is going, metres.
func _run_rail_toward(z: float, dt: float) -> float:
	var target := clampf(z, _run_from, _run_to)
	var before := _rail_z
	_rail_z = move_toward(_rail_z, target, RUN_SPEED * dt)
	if _state != State.HOLDING:
		_hand.z += _rail_z - before
		_hand_from.z += _rail_z - before
	return absf(target - _rail_z)


func _turn_carriage_toward(angle: float, dt: float) -> void:
	var step := clampf(wrapf(angle - _rail_angle, -PI, PI), -RAIL_SPEED * dt, RAIL_SPEED * dt)
	_rail_angle = wrapf(_rail_angle + step, -PI, PI)


static func _angle_of(point: Vector3) -> float:
	return atan2(point.y, point.x)


static func _radius_of(point: Vector3) -> float:
	return Vector2(point.x, point.y).length()


static func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

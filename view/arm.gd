## The Arm: a carriage on a rail round the Bore with a chain-arm and a claw.
## Pressed once it reaches out, catches the crew member by the harness
## between their shoulders and carries them to the nearest Station; left and
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

## Seconds to reach out and catch, and to swing back to the rail.
const REACH_TIME := 0.9
const RETURN_TIME := 0.6
## Carrying speed, metres of path per second.
const CARRY_SPEED := 1.6
## How fast the carriage runs round the rail, radians per second.
const RAIL_SPEED := 4.0
## Where the harness is from the eyes: down the back and behind.
const HARNESS_BELOW_EYES := 0.45
const HARNESS_BEHIND := 0.3
## How far the claw hangs out from the carriage when parked.
const PARKED_REACH := 0.3

var _rail_radius: float
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


func _init(rail_radius: float) -> void:
	_rail_radius = rail_radius
	_hand = _parked_hand()


# --- Commands -------------------------------------------------------------

## The Arm's one button: call it if it is away, let go if it has you.
func press() -> void:
	if _state == State.PARKED or _state == State.RETURNING:
		_state = State.REACHING
	else:
		_state = State.RETURNING
	_t = 0.0
	_hand_from = _hand


## Carry on to the next Station on the crew member's right (side > 0) or
## left (side < 0). Ignored unless holding.
func shift(side: int) -> void:
	_shift = signi(side)


## The shift asked for, taken on the next step (it needs the Stations).
var _shift := 0


func _take_shift(stations: Array[Transform3D]) -> void:
	var count := stations.size()
	if _shift == 0 or count < 2:
		_shift = 0
		return
	var ahead := (_to + 1) % count
	var behind := (_to + count - 1) % count
	var eye := _held
	var sense := _round_to_the_right(eye.basis) * _shift
	var pick: int
	if absf(sense) > 0.1:
		# Go round the ring the way that is right (or left) for the part of
		# it in front of and below the crew member.
		var step := wrapf(_angle_of(stations[ahead].origin) - _angle_of(stations[_to].origin), -PI, PI)
		pick = ahead if signf(step) == signf(sense) else behind
	else:
		# Looking along the Bore with "down" along it too: no part of the
		# ring is below, so take whichever neighbour is further that side
		# as seen now (the prototype's rule).
		var toward := func(i: int) -> float:
			return (stations[i].origin - eye.origin).dot(eye.basis.x) * _shift
		pick = ahead if toward.call(ahead) >= toward.call(behind) else behind
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
			_t = minf(1.0, _t + dt / REACH_TIME)
			var e := _ease(_t)
			# Swing out of the way of the face on the way in.
			_hand = _hand_from.lerp(_harness(eye), e) + Vector3.BACK * sin(PI * _t) * 0.6
			if _t >= 1.0 and not stations.is_empty():
				_state = State.HOLDING
				_from = eye
				_held = eye
				_to = _nearest(eye.origin, stations)
				_u = 0.0
		State.HOLDING:
			_take_shift(stations)
			_carry(dt, stations[_to])
			_body = _held
			_hand = _harness(_held)
		State.RETURNING:
			_t = minf(1.0, _t + dt / RETURN_TIME)
			_hand = _hand_from.lerp(_parked_hand(), _ease(_t))
			if _t >= 1.0:
				_state = State.PARKED
		_:
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


## Which way round the Bore (positive: anticlockwise about +Z) carries the
## crew member to their right, judged where they look: in front and below.
## Every Station's pose shares one basis at a given "down" (the gimbals all
## follow it from the same start), so this is the same at every Station and
## left undoes right. Near zero when that look runs along the Bore.
static func _round_to_the_right(body: Basis) -> float:
	var look := -body.z - body.y
	return Vector3.BACK.cross(look).dot(body.x)


func _nearest(point: Vector3, stations: Array[Transform3D]) -> int:
	var best := 0
	for i in stations.size():
		if point.distance_to(stations[i].origin) < point.distance_to(stations[best].origin):
			best = i
	return best


func _harness(eye: Transform3D) -> Vector3:
	return eye.origin - eye.basis.y * HARNESS_BELOW_EYES + eye.basis.z * HARNESS_BEHIND


func _rail_point() -> Vector3:
	return Vector3(cos(_rail_angle), sin(_rail_angle), 0) * _rail_radius


func _parked_hand() -> Vector3:
	return _rail_point() * (_rail_radius + PARKED_REACH) / _rail_radius


func _turn_carriage_toward(angle: float, dt: float) -> void:
	var step := clampf(wrapf(angle - _rail_angle, -PI, PI), -RAIL_SPEED * dt, RAIL_SPEED * dt)
	_rail_angle = wrapf(_rail_angle + step, -PI, PI)


static func _angle_of(point: Vector3) -> float:
	return atan2(point.y, point.x)


static func _radius_of(point: Vector3) -> float:
	return Vector2(point.x, point.y).length()


static func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

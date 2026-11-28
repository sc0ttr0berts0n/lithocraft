## Navigation's Sweep: the prospecting scan, one narrow beam wound in a spiral
## over the forward hemisphere (real basis: spiral and conical scans, which
## search outward from where a tracking antenna points, and medical imaging's
## picture built from one steered beam of sound). It starts at the edge
## of the Beam's cone and winds outward to square across the axis it began
## about; each turn takes the same time, so its rays lie thickest ahead and
## thin toward the sides, and none goes behind, where the vessel and its
## tunnel are. Owned by DiveSimulation (_sweep).
##
## One ray at a time: each listens for as long as sound takes to go out to
## the range and back (_LISTEN_SPEED_M_S), so a longer range takes longer and
## a Sweep spreads its rays over the steps. It knows nothing of the layout,
## the path or the points: the simulation hands it the axis and the Head's
## place as it starts, asks each step which rays are due, casts them through
## the rock from where the Head then is, and places their echoes as the Sweep
## draws them, as if from where it began (where_placed()), so a vessel that
## moves meanwhile smears its picture.
class_name Sweep
extends RefCounted

## The ranges the crew may set, metres, shortest first.
const RANGES: Array[float] = [100.0, 200.0, 300.0]
## Rays a whole Sweep is sent as, and the turns of its spiral; each turn the
## same share of them. Tuned for play (ADR 0001).
const _RAYS := 1200
const _TURNS := 20
## How fast the Sweep reckons sound goes through rock, metres a second: each
## ray listens 2 x range / this. Rock's own is some 2 to 6 km/s; with _RAYS
## it makes a Sweep about one to three minutes by range. Tuned for play
## (ADR 0001).
const _LISTEN_SPEED_M_S := 4000.0
## The half-angle of the Sweep's own narrow beam, degrees: what its echoes'
## gain is counted from (Echoes.gain_of()). Tuned for play (ADR 0001).
const _BEAM_HALF_ANGLE_DEG := 5.0
## Seconds between the batches its echoes are handed into the cloud in, so
## the cloud and its fit change a few times a turn, not every step. Tuned for
## play (ADR 0001).
const _HAND_IN_S := 1.0

var _range := RANGES[1]
var _running := false
## The running Sweep: what it began about, from where, from what angle off
## its axis, at what range; its rays sent, its time and the time of its last
## batch.
var _axis := Vector3.DOWN
var _origin := Vector3.ZERO
var _from_deg := 35.0
var _running_range := RANGES[1]
var _sent := 0
var _elapsed := 0.0
var _handed_in_at := 0.0


## The range the next Sweep is taken to, one of RANGES.
func range_m() -> float:
	return _range


## Sets the range of the next Sweep; one not in RANGES is ignored.
func set_range(metres: float) -> void:
	if metres in RANGES:
		_range = metres


## Seconds a whole Sweep takes at a range: each of its rays listens for the
## sound to go out and back.
static func duration(metres: float) -> float:
	return _RAYS * listen_s(metres)


## Seconds one ray listens at a range.
static func listen_s(metres: float) -> float:
	return 2.0 * metres / _LISTEN_SPEED_M_S


## How much stronger the Sweep's echoes are than the middle Beam's: its narrow
## beam (Echoes.gain_of()).
static func gain() -> float:
	return Echoes.gain_of(_BEAM_HALF_ANGLE_DEG)


## Starts a Sweep at the set range about `axis` (a unit vector) from `origin`,
## winding out from `from_deg` (the edge of the Beam's cone) to square across.
func start(axis: Vector3, origin: Vector3, from_deg: float) -> void:
	_running = true
	_axis = axis.normalized()
	_origin = origin
	_from_deg = clampf(from_deg, 0.0, 90.0)
	_running_range = _range
	_sent = 0
	_elapsed = 0.0
	_handed_in_at = 0.0


## Ends the running Sweep, finished or cut short.
func stop() -> void:
	_running = false


func running() -> bool:
	return _running


## The running Sweep's range, metres.
func running_range() -> float:
	return _running_range


## The axis the running Sweep winds about and where the Head was as it began.
func axis() -> Vector3:
	return _axis


func origin() -> Vector3:
	return _origin


## Degrees off its axis the running Sweep began at: the Beam's edge.
func from_angle() -> float:
	return _from_deg


## The share of the running Sweep's rays sent, 0 to 1.
func progress() -> float:
	return float(_sent) / _RAYS


## Degrees off its axis the spiral has reached: from from_angle() as it
## starts to 90, square across, as it ends.
func reached_angle() -> float:
	return lerpf(_from_deg, 90.0, progress())


## Seconds left of the running Sweep.
func time_left() -> float:
	return (_RAYS - _sent) * listen_s(_running_range)


## The running Sweep's time goes on by `dt` seconds: the rays now due, each
## an index along the spiral (0 the first), in order. None once all are sent.
func due(dt: float) -> Array[int]:
	var out: Array[int] = []
	if not _running:
		return out
	_elapsed += dt
	var by_now := mini(floori(_elapsed / listen_s(_running_range)), _RAYS)
	while _sent < by_now:
		out.append(_sent)
		_sent += 1
	return out


## Whether the echoes heard since the last batch are now handed into the
## cloud: every _HAND_IN_S of the Sweep's time, and as it finishes.
func hand_in_due() -> bool:
	if _sent >= _RAYS or _elapsed - _handed_in_at >= _HAND_IN_S:
		_handed_in_at = _elapsed
		return true
	return false


## Whether every ray has been sent.
func finished() -> bool:
	return _sent >= _RAYS


## The way ray `index` points about `axis`: at its angle off the axis (rising
## evenly from from_angle() to 90 degrees over the Sweep) and its turn round
## it (_TURNS whole turns, each the same share of the rays). Handed the
## Head's axis now, it is where the ray goes; handed axis(), where it is drawn.
func direction(index: int, about: Vector3) -> Vector3:
	var along := (index + 0.5) / _RAYS
	var off := deg_to_rad(lerpf(_from_deg, 90.0, along))
	var turn := TAU * _TURNS * along
	var side := about.cross(Vector3.RIGHT if absf(about.x) < 0.9 else Vector3.UP).normalized()
	var other_side := about.cross(side)
	return about * cos(off) + (side * cos(turn) + other_side * sin(turn)) * sin(off)


## Where an echo heard `metres` along ray `index` is placed: as if from where
## the Sweep began, about the axis it began about, whatever the vessel has
## done since. Halted it is where the echo came from; under way it is off by
## the way the Head has moved and turned meanwhile.
func where_placed(index: int, metres: float) -> Vector3:
	return _origin + direction(index, _axis) * metres

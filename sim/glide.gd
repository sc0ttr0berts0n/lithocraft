## The Glide, in full the Vapor Glide: the Lithocraft's fast way through rock.
## The Head melts the whole face, the Column included; the melt jets through
## the Bore and leaves at the Tail as thrust, the grippers let go, and the
## vessel runs dead straight in a sheath of melt and vapour at many times the
## Crawl's speed while the crew's clock runs as normal. The plasma touches
## only the melt, so no Wobble reaches it; the jet drowns every pulse; there
## is no Column to survey or to send heat into.
##
## Navigation plots a Glide along the Course, never longer than the scan has
## shown; the Drive starts it from straight on the Course, and it ends at its
## plotted length or when the crew drop out, either way halted with the Head
## at idle and the plasma lit, waiting for the crew to spin it up again.
##
## It is flown (#126): pushed off its line by the sheath's own unsteadiness,
## by rock harder on one side, and by being off it at all, it is held there by
## the Drive's nudges (far finer in a Glide than in the Crawl) or loosely by its autopilot, and
## the Head and hull wear only while it is further off than the sheath's
## slack, faster the further off.
##
## Real basis: supercavitation (a torpedo inside its own gas bubble meets
## almost no drag, is unstable in it, must be steered the whole way and is
## damaged where it slaps the bubble's wall); melting a metre of rock costs
## the same energy at any speed, so many times the speed is at least as many
## times the power; a rocket's exhaust carries most of its heat away.
##
## Owned by DiveSimulation, which steps it and answers for it through its own
## queries (a subsystem: docs/conventions/simulation-interface.md). It knows
## nothing of the layout, the scan or the Stations: how far the scan reaches,
## where the Head is and what it may draw are handed in.
class_name Glide
extends RefCounted

## What the Glide is doing: none (the Crawl, or halted by other means), gliding
## (spinning up or at speed), dropping out (the jet dying, by the crew's
## command or at the plotted length) and idle (halted after a Glide, the Head
## at idle until the crew spin it up).
const NONE := &"none"
const GLIDING := &"gliding"
const DROPPING_OUT := &"dropping_out"
const IDLE := &"idle"
## Why a Glide ended (the &"glide_ended" event's `by`): at its plotted length,
## or the crew dropped out.
const BY_LENGTH := &"plotted_length"
const BY_CREW := &"crew"

## The Reactor's whole output in a Glide at full thrust, in the units of
## set_power(): many times its output under way in the Crawl, which the
## Wobble of solid rock on the plasma holds down. Tuned for play (ADR 0001):
## with _MELT_PER_M it makes the Glide about 64 times the Crawl's best speed in
## the same rock, the developer's "maybe 64x" (16-glide-and-scan.md).
const _OUTPUT := 128.0
## Energy to melt a metre of the whole face, per unit of the rock's hardness,
## in the units of set_power() times seconds: twice the Crawl's (whose Head
## melts only a ring and leaves the Column), so a Glide never takes less
## power per metre than a Crawl. Tuned for play (ADR 0001).
const _MELT_PER_M := 1.0
## Seconds the jet takes to build to full thrust, and to die from it. Tuned
## for play (ADR 0001): a few seconds each, felt but not waited on.
const _SPIN_UP_S := 3.0
const _SPIN_DOWN_S := 2.0
## The share of the Glide's heat that passes out through the hull; the jet
## carries the rest away aft. Tuned for play (ADR 0001): the hull warms
## modestly, more than standing still, much less than a Crawl at full power.
const _HULL_SHARE := 0.002
## The jet's roar as Navigation hears it, in the units of noise(): far above
## anything the Crawl makes. Tuned for play (ADR 0001).
const _JET_NOISE := 5.0
## How far short of the furthest Inferred Boundary along its line a Glide may
## run: beyond the furthest echo the scan has shown nothing, and the scan
## places a Boundary only so well. Tuned for play (ADR 0001): about a worked
## scan's error, a little more than the vessel's length.
const _SHORT_OF_EDGE_M := 15.0
## The least depth a climbing Glide may end at, metres: breaking the surface
## at a Glide's speed would throw the vessel and its melt into the air, so a
## Glide toward the surface ends this far below it and the crew crawl out.
## Tuned for play (ADR 0001).
const _SURFACE_CLEARANCE_M := 20.0
## The longest piece a Glide moves in at once, metres, so a long step at a
## raised time rate meets every Boundary on its way, a thin layer's two
## included: as short as the pieces a Scenario's start moves in. Not tuned
## for play.
const _PIECE_M := 1.0
## How far off the Course, degrees, the Head may point for a Glide to start:
## the Glide runs straight, so turns are the Crawl's. Tuned for play (ADR 0001).
const _STRAIGHT_DEG := 1.0
## How far off its line, metres, the vessel may run without touching the
## sheath's wall: the melt sheath is a little wider than the hull. Tuned for
## play (ADR 0001).
const _SLACK_M := 1.0
## Past the slack, metres, at which the vessel is hard against the wall and
## wears its fastest: further off it wears no faster. Tuned for play (ADR
## 0001): a careless few hundred metres costs, but does not kill.
const _HARD_AGAINST_M := 4.0
## Head and hull wear for each metre glided, per metre past the slack. Tuned
## for play (ADR 0001): a few hundred metres left alone wears a few hundredths
## of the Head and fewer of the hull; on the autopilot, a fraction of that.
const _HEAD_WEAR_PER_M2 := 1.5e-4
const _HULL_WEAR_PER_M2 := 0.75e-4
## The sheath's own unsteadiness: a sideways push, as the slope of the way
## the vessel runs (metres across per metre along), up to this much on each
## axis, changing smoothly over _WANDER_M of the line. Tuned for play (ADR
## 0001): about a degree, a few nudges to hold.
const _WANDER := 0.015
const _WANDER_M := 200.0
## Being off its line pushes the vessel further off, per metre off, up to
## _WANDER at most: a body in its bubble is unstable. Tuned for play (ADR
## 0001).
const _UNSTABLE_PER_M := 1.0 / 250.0
## Rock harder on one side than the other pushes the vessel toward the softer
## side: the slope at the most different rock either side. Tuned for play
## (ADR 0001): a felt kick through an oblique Boundary.
const _ROCK_PUSH := 0.1
## How far either side of the Head the rock is felt, metres: about the hull's
## radius. Tuned for play (ADR 0001).
const _SIDE_M := 3.0
## One nudge of the Drive's in a Glide, degrees: far finer than a nudge in the
## Crawl, since the Glide runs straight. Tuned for play (ADR 0001).
const _NUDGE_DEG := 0.25
## The line to hold is drawn as where the line is this far ahead, metres:
## steering onto it rejoins the line within about as far. Tuned for play
## (ADR 0001).
const _AIM_M := 50.0
## The Drive's autopilot lets the vessel wander this far off the line,
## metres, before it nudges back, and then rejoins within about
## _AUTOPILOT_REJOIN_M: safe but mediocre, it rides just past the slack and
## wears a little. Tuned for play (ADR 0001).
const _AUTOPILOT_LOOSE_M := 1.25
const _AUTOPILOT_REJOIN_M := 20.0
## Metres from its end at which a Glide counts as there. Not tuned for play.
const _ARRIVED_M := 0.01
## The least thrust a Glide dropping out at its plotted length keeps until it
## is there, so a drop-out begun a little early still arrives rather than
## creeping the last metres. Tuned for play (ADR 0001).
const _ARRIVING_THRUST := 0.05
## Seconds of range left at which the Drive reports the Glide ending. Tuned
## for play (ADR 0001).
const _ENDING_CALL_S := 10.0

var _plotted := 0.0
var _state := NONE
var _ended_by := BY_LENGTH
## The running Glide's line: where it began, the way it runs (unit length)
## and how long it is, metres.
var _origin := Vector3.ZERO
var _direction := Vector3.DOWN
var _length := 0.0
## The jet's thrust, 0 (the Crawl's output) to 1 (the whole Glide output).
var _thrust := 0.0
## Each Glide this dive: the path distance it began at and the one it has
## reached, oldest first, in full precision (a Vector2's would round the
## Head's own distance away from itself).
var _began := PackedFloat64Array()
var _reached := PackedFloat64Array()
## The scan's guess of the Wobble of the rock this Glide last entered, as it
## stood just before the crossing; null while it has crossed none.
var _rock_entered: WobbleGuess = null
## The running Glide's two axes across its line, unit length: to the right
## (the way a heading nudge turns) and steeper (the way a pitch nudge tips),
## as the attitude ball has them.
var _right := Vector3.RIGHT
var _steeper := Vector3.FORWARD
## Metres along the line run so far, and metres off it on the two axes
## (right, steeper).
var _along := 0.0
var _off := Vector2.ZERO
## Where the Drive's nudges hold the Glide, as the slope they add on each axis
## (right, steeper).
var _held := Vector2.ZERO
## The slope the vessel ran at over the last piece, on each axis.
var _slope := Vector2.ZERO
## Metres past the slack times metres of the last piece flown: what it wore.
var _slapped := 0.0
## The sheath's unsteadiness: its push at each _WANDER_M of the line, drawn
## from `_random` as the Glide reaches it, so a Glide's push is the same each
## time it is flown.
var _knots := PackedVector2Array()
var _random := RandomNumberGenerator.new()


## Navigation plots a Glide of `metres` along the Course, held to `reach`, the
## most the scan has shown; 0 clears it.
func plot(metres: float, reach: float) -> void:
	_plotted = clampf(metres, 0.0, maxf(reach, 0.0))


## The plotted Glide's length, metres; 0 for none.
func plotted() -> float:
	return _plotted


## What the Glide is doing: NONE, GLIDING, DROPPING_OUT or IDLE.
func state() -> StringName:
	return _state


## True from the start of a Glide until it halts: no Wobble, no Column, the
## jet's power, heat and noise.
func active() -> bool:
	return _state == GLIDING or _state == DROPPING_OUT


## True while halted with the Head at idle after a Glide.
func idle() -> bool:
	return _state == IDLE


## True while the jet dies, the Glide about to halt.
func dropping_out() -> bool:
	return _state == DROPPING_OUT


## Starts the plotted Glide from `origin` along `direction` (unit length),
## `reach` metres being the most the scan shows from there, at path distance
## `distance`, the Head's compass heading `heading_degrees` (its last while
## vertical) setting which way is right; `seed` seeds its push. The plot is
## spent.
func start(origin: Vector3, direction: Vector3, reach: float, distance: float,
		heading_degrees: float, seed: int) -> void:
	_origin = origin
	_direction = direction
	var h := deg_to_rad(heading_degrees)
	var right := Vector3(cos(h), 0.0, sin(h))
	_right = (right - direction * right.dot(direction)).normalized()
	_steeper = direction.cross(_right).normalized()
	_along = 0.0
	_off = Vector2.ZERO
	_held = Vector2.ZERO
	_slope = Vector2.ZERO
	_slapped = 0.0
	_knots = PackedVector2Array()
	_random.seed = seed
	_length = minf(_plotted, reach)
	_plotted = 0.0
	_state = GLIDING
	_thrust = 0.0
	_ended_by = BY_LENGTH
	_rock_entered = null
	_began.append(distance)
	_reached.append(distance)


## The running Glide's length, metres.
func length() -> float:
	return _length


## Where the running Glide ends, in the world frame.
func end() -> Vector3:
	return _origin + _direction * _length


## The way the running Glide runs, unit length.
func direction() -> Vector3:
	return _direction


## Metres from `position` along the running Glide's line to its end.
func left(position: Vector3) -> float:
	return maxf(_length - (position - _origin).dot(_direction), 0.0)


## The Drive nudges the Glide one step: right for a positive `right`, left for
## a negative one, steeper for a positive `steeper`, shallower for a negative
## one; only the signs count.
func nudge(right: float, steeper: float) -> void:
	_held += Vector2(signf(right), signf(steeper)) * tan(deg_to_rad(_NUDGE_DEG))


## One nudge, degrees.
static func nudge_degrees() -> float:
	return _NUDGE_DEG


## Flies `piece_m` metres along the line, pushed by `rock_push` (the slope
## rock harder on one side gives, Glide.rock_push()), by the sheath's own
## unsteadiness and by being off the line, and held where the Drive's nudges set it or,
## if `autopilot`, by its autopilot's loose rule, which sets that hold (left
## where it was when the autopilot lets go). Returns the way the vessel moved,
## in the world frame; slapped() is what it wore.
func fly(piece_m: float, rock_push: Vector2, autopilot: bool) -> Vector3:
	if autopilot:
		var beyond := _off.length() - _AUTOPILOT_LOOSE_M
		_held = Vector2.ZERO if beyond <= 0.0 else -_off.normalized() * beyond / _AUTOPILOT_REJOIN_M
	var unstable := (_off * _UNSTABLE_PER_M).limit_length(_WANDER)
	_slope = _held + rock_push + _wander(_along + piece_m * 0.5) + unstable
	_along += piece_m
	_off += _slope * piece_m
	_slapped = clampf(_off.length() - _SLACK_M, 0.0, _HARD_AGAINST_M) * piece_m
	return (_direction + _right * _slope.x + _steeper * _slope.y) * piece_m


## The sheath's own push `along` metres down the line: smooth between knots
## drawn as the Glide first reaches them, so the same Glide flown again is
## pushed the same.
func _wander(along: float) -> Vector2:
	var at := along / _WANDER_M
	var knot := floori(at)
	while _knots.size() < knot + 2:
		_knots.append(Vector2(_random.randf_range(-1.0, 1.0), _random.randf_range(-1.0, 1.0)) * _WANDER)
	var t := at - knot
	return _knots[knot].lerp(_knots[knot + 1], t * t * (3.0 - 2.0 * t))


## The way the vessel runs now, unit length: its line tipped by the slope it
## ran at over the last piece.
func running_way() -> Vector3:
	return (_direction + _right * _slope.x + _steeper * _slope.y).normalized()


## Metres off the line now, Vector2(to the right, steeper).
func off_line() -> Vector2:
	return _off


## What the last piece flown wore, in metres past the slack times metres;
## head_wear() and hull_wear() make each wear of it.
func slapped() -> float:
	return _slapped


## How far off its line, metres, the vessel may run and wear nothing.
static func slack() -> float:
	return _SLACK_M


## How hard against the sheath's wall the vessel is: 0 inside the slack, 1
## hard against it.
func contact_share() -> float:
	return clampf((_off.length() - _SLACK_M) / _HARD_AGAINST_M, 0.0, 1.0) if active() else 0.0


## The Head's wear for `slapped` (slapped()).
static func head_wear(slapped: float) -> float:
	return slapped * _HEAD_WEAR_PER_M2


## The hull's wear for `slapped` (slapped()).
static func hull_wear(slapped: float) -> float:
	return slapped * _HULL_WEAR_PER_M2


## The slope with which rock harder on one side pushes the vessel toward the
## softer, Vector2(right, steeper), from the hardness either side of the Head:
## right and left, steeper and shallower.
static func rock_push(right: float, left: float, steeper: float, shallower: float) -> Vector2:
	return Vector2((left - right) / maxf(left + right, 1e-6),
			(shallower - steeper) / maxf(shallower + steeper, 1e-6)) * _ROCK_PUSH


## Where the rock is felt either side of a Head at `position`: right, left,
## steeper and shallower of it.
func sides(position: Vector3) -> PackedVector3Array:
	return PackedVector3Array([position + _right * _SIDE_M, position - _right * _SIDE_M,
			position + _steeper * _SIDE_M, position - _steeper * _SIDE_M])


## The line to hold, as a unit direction from a Head at `position`: toward
## where the line is _AIM_M ahead, so steering onto it rejoins the line.
func aim(position: Vector3) -> Vector3:
	var ahead := _origin + _direction * ((position - _origin).dot(_direction) + _AIM_M)
	return (ahead - position).normalized()


## The crew drop out: the jet dies and the vessel halts short of the end.
func drop_out() -> void:
	if _state == GLIDING:
		_state = DROPPING_OUT
		_ended_by = BY_CREW


## One step of dt seconds of the jet, `left_m` metres from the end at `speed`
## metres a second: it builds toward full thrust, or dies while dropping out.
## Run to its plotted length, it begins to die in time to halt at the end
## (thrust falling evenly, the vessel runs half its speed times the seconds
## the jet takes to die), and is then held to the thrust that still arrives
## there, which harder rock entered on the way raises: never below a little
## until it is there, never changing faster than the jet builds or dies.
func spin(dt: float, left_m: float, speed: float) -> void:
	if _state == GLIDING and left_m <= speed * _thrust * _SPIN_DOWN_S * 0.5:
		_state = DROPPING_OUT
	if _state == GLIDING:
		_thrust = minf(_thrust + dt / _SPIN_UP_S, 1.0)
	elif _state == DROPPING_OUT and _ended_by == BY_CREW:
		_thrust = maxf(_thrust - dt / _SPIN_DOWN_S, 0.0)
	elif _state == DROPPING_OUT:
		var arrives := 1.0
		if speed > 0.0 and _thrust > 0.0:
			arrives = sqrt(2.0 * left_m * _thrust / (speed * _SPIN_DOWN_S))
		var held := clampf(arrives, _thrust - dt / _SPIN_DOWN_S, _thrust + dt / _SPIN_UP_S)
		_thrust = clampf(held, _ARRIVING_THRUST if left_m > _ARRIVED_M else 0.0, 1.0)


## The Reactor's output in a Glide at the thrust now, from `crawl_output`
## (its full output in the Crawl) to the whole Glide output; times the
## plasma's steadiness, by the simulation.
func output(crawl_output: float) -> float:
	return lerpf(crawl_output, _OUTPUT, _thrust)


## Metres a second a Glide makes on `power` through rock of this `hardness`:
## melting the whole face costs the same energy a metre at any speed, so more
## speed needs more power.
static func speed(power: float, hardness: float) -> float:
	return power / (maxf(hardness, 1e-6) * _MELT_PER_M)


## The share of the Glide's heat that passes out through the hull; the jet
## carries the rest away.
static func hull_share() -> float:
	return _HULL_SHARE


## The jet's noise, as Navigation hears it.
static func jet_noise() -> float:
	return _JET_NOISE


## The longest piece a Glide moves in at once, metres.
static func piece() -> float:
	return _PIECE_M


## How far off the Course, degrees, the Head may point for a Glide to start.
static func straight_degrees() -> float:
	return _STRAIGHT_DEG


## Seconds of range left at which the Drive reports the Glide ending.
static func ending_call_seconds() -> float:
	return _ENDING_CALL_S


## How far a Glide may run along a line from a Head `depth` metres down
## pointing `direction` (unit length, the world frame, +Y up), when the scan
## shows its furthest Inferred Boundary along that line `furthest_m` ahead (0
## for none): short of it by a margin, and short of the surface on a climb.
static func reach(furthest_m: float, depth: float, direction: Vector3) -> float:
	if furthest_m <= 0.0:
		return 0.0
	var shown := furthest_m - _SHORT_OF_EDGE_M
	if direction.y > 0.0:
		shown = minf(shown, (depth - _SURFACE_CLEARANCE_M) / direction.y)
	return maxf(shown, 0.0)


## The Glide has moved on to path distance `distance`.
func moved(distance: float) -> void:
	_reached[_reached.size() - 1] = distance


## A Boundary was crossed in the Glide, the scan's guess of the rock beyond
## it standing as `guess`: that is now the rock the Glide is in.
func crossed(guess: WobbleGuess) -> void:
	_rock_entered = guess


## The jet's thrust now, 0 (the Crawl's output) to 1.
func thrust() -> float:
	return _thrust


## The scan's guess of the rock the Glide last entered, or null if it crossed
## no Boundary.
func rock_entered() -> WobbleGuess:
	return _rock_entered


## True once the running Glide should halt, `left_m` from its end: at the end,
## or with the jet died away.
func finished(left_m: float) -> bool:
	return active() and (left_m <= _ARRIVED_M or (_state == DROPPING_OUT and _thrust <= 0.0))


## The Glide halts, the Head at idle; returns why it ended (BY_LENGTH or
## BY_CREW).
func finish(left_m: float) -> StringName:
	_state = IDLE
	_thrust = 0.0
	if left_m <= _ARRIVED_M:
		_ended_by = BY_LENGTH
	return _ended_by


## The crew spin the Head up out of the idle: the Crawl may begin.
func spin_up() -> void:
	if _state == IDLE:
		_state = NONE


## Everything stops at once, with no idle (the plasma lost, the hull failed,
## the dive over).
func halt() -> void:
	_state = NONE
	_thrust = 0.0


## Each Glide this dive, Vector2(path distance it began at, reached), oldest
## first. A copy.
func stretches() -> PackedVector2Array:
	var stretches := PackedVector2Array()
	for i in _began.size():
		stretches.append(Vector2(_began[i], _reached[i]))
	return stretches


## True when there is no Column at path distance `at`: a Glide melted it, from
## the Column already in the Bore as it began (`bore_m` behind the Head) to
## where it reached. Looks back only over Glides that reach past `at`, so a
## place behind the newest costs one comparison.
func column_gone(at: float, bore_m: float) -> bool:
	for i in range(_began.size() - 1, -1, -1):
		if at > _reached[i]:
			return false
		if at >= _began[i] - bore_m:
			return true
	return false


## The part of the path between distances `from` and `to` that a Glide cut,
## as [start, end], or [to, to] when none did. Glides that meet are one part.
## Looks back only over Glides that reach past `from`, so a piece of tunnel
## the Tail leaves behind the newest costs one comparison.
func glided_within(from: float, to: float) -> PackedFloat64Array:
	var start := INF
	var end := -INF
	for i in range(_began.size() - 1, -1, -1):
		if _reached[i] <= from:
			break
		var a := maxf(from, _began[i])
		var b := minf(to, _reached[i])
		if b > a:
			start = minf(start, a)
			end = maxf(end, b)
	return PackedFloat64Array([start, end]) if end > start else PackedFloat64Array([to, to])


## Metres the newest Glide this dive has run; 0 with none.
func glided() -> float:
	return 0.0 if _began.is_empty() else _reached[-1] - _began[-1]

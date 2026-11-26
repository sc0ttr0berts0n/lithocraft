## The Head's plasma: the Wobble, the Counter-wave, the Residual and the Band.
## The Medium being cut puts a Wobble on the plasma, with its own frequency
## and amplitude in every Medium. The Reactor cancels it by driving its
## inverse, the Counter-wave; what is left of the two summed is the Residual:
## flat when the cancelling is perfect, a small steady wave when the amplitude
## is off, slow beats when the frequency is off. The Band is how much Residual
## the Head bears: inside it nothing wears; outside it the Head grinds (heat,
## a shudder, wear), harder the further out, and the plasma is less steady.
## The Band narrows as the Head wears and as the hull runs hot.
##
## The Shift dial holds two Counter-waves: ACTIVE cancels now, STANDBY is
## prepared for the Medium ahead, and the Shift swaps them. A plasma lost (a
## Head worn through, or a Residual far outside the Band on a badly worn
## Head) can be struck again by a relight, paid for from the emergency store;
## the odds fall with the Head's wear.
##
## Real basis: tokamaks hold their plasma by sensing a growing magnetic
## wobble and driving coils with the opposite field (resistive-wall-mode and
## error-field feedback); two waves of unlike frequency summed beat at the
## difference of their frequencies; a phase-locked loop holds phase by itself
## once near in frequency.
##
## Owned by DiveSimulation, which tends it once a step and answers for it
## through its own queries. Knows nothing of the layout or the Stations: the
## Wobble now and everything else it needs are handed in.
class_name Plasma
extends RefCounted

## The Shift dial's two channels.
const ACTIVE := &"active"
const STANDBY := &"standby"
## The causes that can pull the plasma's steadiness down (see causes()).
const CAUSE_WORN := &"worn"
const CAUSE_HOT := &"hot"
const CAUSE_OUT_OF_BAND := &"out_of_band"

## Frequency of the Wobble per root of hardness, in hertz (a frequency a crew
## can see on a screen, not a real plasma mode). Tuned for play (ADR 0001).
const _WOBBLE_HZ_PER_ROOT_HARDNESS := 0.8
## The Wobble's amplitude in a Medium with no strength at all and in one
## endlessly strong: stronger rock pushes back on the Head harder, so its
## Wobble is bigger. Amplitudes have no unit; 1 is about the biggest Wobble.
## Tuned for play (ADR 0001); only the ordering is meant true.
const _WOBBLE_AMPLITUDE_WEAK := 0.4
const _WOBBLE_AMPLITUDE_STRONG := 1.0
## The most a Counter-wave's amplitude can be set to.
const _AMPLITUDE_MAX := 2.0
## How far a Counter-wave's frequency may be from the Wobble's, as a share of
## it, before the phase lock lets go altogether: nearer than this the lock
## holds the Counter-wave's phase to the Wobble's on average and the phase
## only swings about it, less the nearer; at this and beyond it swings a full
## half turn each way, so the two waves add as often as they cancel.
## Tuned for play (ADR 0001).
const _LOCK_RANGE := 0.5
## The Band of a fresh Head with the hull cool: the Residual it bears.
const _BAND := 0.2
## How much of the Band a Head worn through has lost, and a hull as hot as it
## can bear takes. A worn or hot Head is less forgiving. Tuned for play.
const _WEAR_NARROWING := 0.5
const _HEAT_NARROWING := 0.4
## Wear on the Head per second for each unit of Residual outside the Band.
## Tuned for play (ADR 0001): left to the autopilot, the First dive's four
## Boundaries wear the Head well short of half; left alone, the Residual a
## Boundary leaves loses a fresh Head in a few minutes.
const _WEAR_PER_S := 0.008
## Residual outside the Band at which the plasma is half as steady, and so
## the Reactor's output halves. Tuned for play (ADR 0001).
const _UNSTEADY_HALF := 0.6
## How much a fully worn Head unsteadies the plasma even when the Residual is
## flat, so the Reactor delivers less power at the same setting.
const _WEAR_UNSTEADINESS := 0.3
## A cause is reported (causes()) once it alone costs this much steadiness.
const _CAUSE_TELLS := 0.01
## Residual outside the Band at which the Head grinds at its roughest, and
## what that costs: extra heat per second, and a shudder along the Bore in
## m/s^2, at this many hertz. Tuned for play (ADR 0001).
const _ROUGH_RESIDUAL := 0.6
const _GRIND_HEAT := 0.4
const _SHUDDER_ACCELERATION := 3.0
const _SHUDDER_HZ := 3.0
## A Residual far outside the Band can disrupt the plasma on a badly worn
## Head: it is lost once the roughness of the Residual at its fullest times
## the Head's wear has stayed at or above _DISRUPTION for _DISRUPTION_S
## seconds. A fresh Head never loses it so; a badly worn one can lose it to
## any rough Residual, well short of worn through, but rides out the few
## seconds a swap at a Boundary takes a crew. Tuned for play (ADR 0001).
const _DISRUPTION := 0.5
const _DISRUPTION_S := 4.0
## How fast the Reactor's autopilot tunes ACTIVE toward the Wobble: frequency
## as a share per second of the higher of the two frequencies (so a Boundary
## takes it about as long up as down), amplitude per second. Slow, so it
## wears the Head through each Boundary. Tuned for play (ADR 0001).
const _AUTOPILOT_FREQUENCY_PER_S := 0.03
const _AUTOPILOT_AMPLITUDE_PER_S := 0.02
## A debug detune's frequency, as a multiple of the Wobble's.
const _DEBUG_DETUNE := 1.3
## A relight: the energy of the pulse that strikes the plasma again, in the
## units of set_power() times seconds, and the chance it takes on a fresh Head
## and on one worn through (between, it falls with the wear). Real basis: a
## tokamak cannot restart itself; striking a plasma takes a large pulse of
## stored energy, and a worn wall fouls it with impurities that can stop it
## taking. Tuned for play (ADR 0001): a healthy Head almost always relights.
const _RELIGHT_PULSE := 40.0
const _RELIGHT_FRESH := 0.95
const _RELIGHT_WORN_THROUGH := 0.4
## The most samples of the Residual taken across one step.
const _SAMPLES := 16

## The Band at its widest: a fresh Head's with the hull cool.
static func band_widest() -> float:
	return _band_of(0.0, 0.0)


## How steady the plasma is, 0 (lost) to 1 (steady). The Reactor's output
## scales with it.
var _stability := 1.0
## Each channel's Counter-wave: {ACTIVE: Vector2(frequency in hertz,
## amplitude), STANDBY: ...}.
var _counter := {}
## The channel the Reactor's controls tune.
var _selected := STANDBY
## A Shift (the swap) asked for since the last step.
var _shift_asked := false
## Wear on the Head, 0 (none) to 1 (the plasma is lost).
var _head_wear := 0.0
## True once the plasma has gone out. It stays out until relit.
var _lost := false
## Why the plasma went out (see lost_by()), or &"" while it holds.
var _lost_by := &""
## Seconds the plasma has been tended: the clock the waves run on.
var _time := 0.0
## Where ACTIVE's phase stands in its swing about the Wobble's, in radians.
var _swing_phase := 0.0
## The Band at the last step.
var _band := _BAND
## How rough the Head's grinding was over the last step, 0 (none: the
## Residual inside the Band) to 1.
var _roughness := 0.0
## Seconds the Residual has stayed rough enough to disrupt the plasma on this
## Head (see _DISRUPTION), 0 while it is not.
var _disrupting_for := 0.0


## Starts steady, both channels cancelling this Wobble (frequency in hertz,
## amplitude).
func _init(wobble: Vector2) -> void:
	_counter = {ACTIVE: wobble, STANDBY: wobble}


## The Wobble cutting this Medium puts on the plasma: Vector2(frequency in
## hertz, amplitude). Harder rock loads the Head more and wobbles it faster;
## stronger rock pushes back harder and wobbles it bigger.
static func wobble_in(medium: Medium) -> Vector2:
	return Vector2(_WOBBLE_HZ_PER_ROOT_HARDNESS * sqrt(medium.hardness),
			lerpf(_WOBBLE_AMPLITUDE_WEAK, _WOBBLE_AMPLITUDE_STRONG,
					medium.strength / (1.0 + medium.strength)))


## Energy the pulse that relights the plasma takes from the emergency store.
func relight_cost() -> float:
	return _RELIGHT_PULSE


## The chance a relight strikes the plasma on this Head, 0 to 1: high on a
## fresh Head, falling with its wear.
func relight_chance() -> float:
	return lerpf(_RELIGHT_FRESH, _RELIGHT_WORN_THROUGH, _head_wear)


## Tries to strike the lost plasma again, its pulse already paid for. `roll`
## (0 to 1, uniformly random) below relight_chance() lights it, ACTIVE
## cancelling `wobble` so it holds at once. The Head keeps its wear.
## Returns whether it lit; false, and nothing changed, if it was not lost.
func relight(wobble: Vector2, roll: float) -> bool:
	if not _lost or roll >= relight_chance():
		return false
	_lost = false
	_lost_by = &""
	_counter[ACTIVE] = wobble
	_shift_asked = false
	_roughness = 0.0
	_disrupting_for = 0.0
	_stability = 1.0 - _WEAR_UNSTEADINESS * _head_wear
	return true


## Debug only (DiveSimulation's debug commands): sets the Head's wear, 0 to 1.
## It does not lose the plasma: only a Residual outside the Band does that.
func debug_set_wear(wear: float) -> void:
	_head_wear = clampf(wear, 0.0, 1.0)


## Debug only: the plasma goes out, as a Residual that loses it would leave
## it, by the same path (_lose()), raising &"plasma_lost" into `events`. Its
## cause is &"debug".
func debug_lose(events: Array[Dictionary], depth: float, distance: float) -> void:
	_go_dark(events, depth, distance, &"debug")


## A Scenario's start (DiveSimulation.start_dark()): the Head worn `wear`, 0
## to 1, and the plasma lost by the path any loss takes (_lose()), raising
## &"plasma_lost" into `events`. Its cause is &"scenario".
func start_dark(wear: float, events: Array[Dictionary], depth: float, distance: float) -> void:
	_head_wear = clampf(wear, 0.0, 1.0)
	_go_dark(events, depth, distance, &"scenario")


## The plasma goes out here, not by its Residual (debug_lose(), start_dark()):
## lost for `cause`, with no Shift left waiting.
func _go_dark(events: Array[Dictionary], depth: float, distance: float, cause: StringName) -> void:
	_lose(events, depth, distance, cause)
	_shift_asked = false


## The plasma goes out and stays out, for `cause` (see lost_by()). Raises
## &"plasma_lost" into `events`, placed at `depth` and `distance`.
func _lose(events: Array[Dictionary], depth: float, distance: float,
		cause: StringName) -> void:
	_lost = true
	_lost_by = cause
	_stability = 0.0
	_roughness = 0.0
	events.append({type = &"plasma_lost", cause = cause, depth = depth, distance = distance})


## Debug only: ACTIVE's Counter-wave is set well wide of `wobble` in
## frequency, so its Residual beats outside the Band from the next step.
func debug_detune(wobble: Vector2) -> void:
	if _lost:
		return
	_counter[ACTIVE] = Vector2(wobble.x * _DEBUG_DETUNE, wobble.y)


## Selects the channel (ACTIVE or STANDBY) the Reactor's controls tune.
func select(channel: StringName) -> void:
	if _counter.has(channel):
		_selected = channel


## The channel the Reactor's controls tune: STANDBY until the crew selects
## ACTIVE. A Shift leaves it as it was.
func selected() -> StringName:
	return _selected


## Sets the frequency, in hertz, of the selected channel's Counter-wave.
func tune_frequency(frequency: float) -> void:
	_counter[_selected] = Vector2(maxf(frequency, 0.0), _counter[_selected].y)


## Sets the amplitude of the selected channel's Counter-wave.
func tune_amplitude(amplitude: float) -> void:
	_counter[_selected] = Vector2(_counter[_selected].x, clampf(amplitude, 0.0, _AMPLITUDE_MAX))


## A channel's Counter-wave: Vector2(frequency in hertz, amplitude).
func counter_wave(channel: StringName) -> Vector2:
	return _counter[channel]


## Asks for a Shift, made on the next tend(): the swap, STANDBY's Counter-wave
## becoming ACTIVE's and the old ACTIVE's dropping to STANDBY. Asked twice
## before a step, it is still one swap.
func ask_shift() -> void:
	_shift_asked = true


## Once a step of dt seconds, before the power is shared, with the Medium's
## `wobble` (frequency in hertz, amplitude) on the plasma: takes a Shift asked
## for, lets the autopilot tune ACTIVE toward the Wobble while `autopilot_on`,
## then sets the Band, wears the Head for the Residual outside it, and sets
## how steady the plasma is and why. `hull_heat_share` (0 cool to 1 as hot as
## the hull can bear) narrows the Band. Raises &"shift_result" and
## &"plasma_lost" into `events`, placed at `depth` and `distance`.
func tend(dt: float, wobble: Vector2, autopilot_on: bool, hull_heat_share: float,
		events: Array[Dictionary], depth: float, distance: float) -> void:
	if _lost:
		_shift_asked = false
		_stability = 0.0
		return
	_band = _band_of(_head_wear, hull_heat_share)
	if _shift_asked:
		_shift_asked = false
		var old: Vector2 = _counter[ACTIVE]
		_counter[ACTIVE] = _counter[STANDBY]
		_counter[STANDBY] = old
		var reach := residual_reach(_counter[ACTIVE], wobble)
		events.append({type = &"shift_result", clean = reach <= _band, residual = reach,
				band = _band})
	if autopilot_on:
		var active: Vector2 = _counter[ACTIVE]
		_counter[ACTIVE] = Vector2(
				move_toward(active.x, wobble.x,
						_AUTOPILOT_FREQUENCY_PER_S * maxf(active.x, wobble.x) * dt),
				move_toward(active.y, wobble.y, _AUTOPILOT_AMPLITUDE_PER_S * dt))
	# The Residual across the step, sampled along ACTIVE's swing: how far it
	# stood outside the Band on average (the wear, the unsteadiness) and at
	# its furthest (the grinding's roughness).
	var counter: Vector2 = _counter[ACTIVE]
	var swing_rate := PI * absf(counter.x - wobble.x)
	var samples := clampi(ceili(swing_rate * dt * 8.0 / PI), 1, _SAMPLES)
	var sizes := PackedFloat32Array()
	var furthest := 0.0
	for i in samples:
		var phase := _swing_phase + swing_rate * dt * (i + 0.5) / samples
		var size := _size(wobble.y, counter.y, _swing(counter, wobble) * sin(phase))
		sizes.append(size)
		furthest = maxf(furthest, size)
	_swing_phase = fposmod(_swing_phase + swing_rate * dt, TAU)
	_time += dt
	var outside := _outside(sizes, _band)
	_roughness = clampf((furthest - _band) / _ROUGH_RESIDUAL, 0.0, 1.0)
	# A Residual left far outside the Band disrupts the plasma on a badly
	# worn Head; wearing the Head through loses it. Inside the Band neither
	# can happen, whatever the wear.
	var disrupting := minf(out_share(wobble), 1.0) * _head_wear >= _DISRUPTION
	_disrupting_for = _disrupting_for + dt if disrupting else 0.0
	if _disrupting_for >= _DISRUPTION_S:
		_lose(events, depth, distance, &"disrupted")
		return
	if outside > 0.0:
		_head_wear = minf(1.0, _head_wear + _WEAR_PER_S * outside * dt)
		if _head_wear >= 1.0:
			_lose(events, depth, distance, &"worn_through")
			return
	_stability = _steadiness(_head_wear, outside)


## The Band on a Head worn `wear` with the hull's heat at `hull_heat_share`.
static func _band_of(wear: float, hull_heat_share: float) -> float:
	return _BAND * (1.0 - _WEAR_NARROWING * wear) \
			* (1.0 - _HEAT_NARROWING * clampf(hull_heat_share, 0.0, 1.0))


## How far these sizes of the Residual stand outside `band`, on average.
static func _outside(sizes: PackedFloat32Array, band: float) -> float:
	var total := 0.0
	for size in sizes:
		total += maxf(0.0, size - band)
	return total / sizes.size()


## How steady the plasma is on a Head worn `wear` with its Residual `outside`
## the Band (on average).
static func _steadiness(wear: float, outside: float) -> float:
	return (1.0 - _WEAR_UNSTEADINESS * wear) / (1.0 + outside / _UNSTEADY_HALF)


## How far the phase of a Counter-wave swings each way about the Wobble's, in
## radians: nothing on its frequency, a half turn at _LOCK_RANGE and beyond.
static func _swing(counter: Vector2, wobble: Vector2) -> float:
	if wobble.x <= 0.0:
		return 0.0
	return PI * minf(1.0, absf(counter.x - wobble.x) / (wobble.x * _LOCK_RANGE))


## The size of the wave left when a wave of amplitude `a` is summed with the
## inverse of one of amplitude `b` that is `phase` radians out of step.
static func _size(a: float, b: float, phase: float) -> float:
	return sqrt(maxf(0.0, a * a + b * b - 2.0 * a * b * cos(phase)))


## The steady part of the Residual a Counter-wave leaves of a Wobble: what the
## amplitudes' difference leaves, the same at every moment.
static func residual_steady(counter: Vector2, wobble: Vector2) -> float:
	return absf(wobble.y - counter.y)


## The beating part of the Residual: how much further it swells, at its
## fullest, because the frequencies differ. 0 on frequency.
static func residual_beat(counter: Vector2, wobble: Vector2) -> float:
	return residual_reach(counter, wobble) - residual_steady(counter, wobble)


## The Residual at its fullest: the steady part and the beating part.
static func residual_reach(counter: Vector2, wobble: Vector2) -> float:
	return _size(wobble.y, counter.y, _swing(counter, wobble))


## How often the Residual's beats come, in hertz: the difference of the two
## frequencies. 0 on frequency.
static func beat_frequency(counter: Vector2, wobble: Vector2) -> float:
	return absf(counter.x - wobble.x)


## The Wobble `wobble` as a wave, `seconds` from now (negative: ago).
func wobble_wave(wobble: Vector2, seconds: float) -> float:
	return wobble.y * sin(TAU * wobble.x * (_time + seconds))


## Plain sines summed, as a wave on the plasma's clock `seconds` from now:
## each Vector3(frequency in hertz, amplitude, phase in radians). The
## spurious sines of the scan's guess of the Wobble ahead (WobbleGuess).
func sines_wave(sines: Array[Vector3], seconds: float) -> float:
	var total := 0.0
	for sine in sines:
		total += sine.y * sin(TAU * sine.x * (_time + seconds) + sine.z)
	return total


## A channel's Counter-wave as a wave, `seconds` from now, against `wobble`:
## its inverse, with the phase swinging about the Wobble's when the frequency
## is off. Summed with wobble_wave() it is the Residual.
func counter_wave_against(channel: StringName, wobble: Vector2, seconds: float) -> float:
	var counter: Vector2 = _counter[channel]
	var swing_phase := _swing_phase + PI * absf(counter.x - wobble.x) * seconds
	return -counter.y * sin(TAU * wobble.x * (_time + seconds)
			+ _swing(counter, wobble) * sin(swing_phase))


## A channel's Counter-wave as a wave with no Wobble to lock to, `seconds`
## from now: a plain wave at its own frequency.
func counter_wave_alone(channel: StringName, seconds: float) -> float:
	var counter: Vector2 = _counter[channel]
	return -counter.y * sin(TAU * counter.x * (_time + seconds))


## The Band: how much Residual the Head bears without wearing, as it is now.
func band() -> float:
	return _band


## How steady the plasma is, 0 (lost) to 1 (steady).
func stability() -> float:
	return _stability


## The causes pulling the steadiness down now, each named once, with
## `wobble` on the plasma and the hull's heat at `hull_heat_share`: CAUSE_WORN
## (the Head's wear), CAUSE_HOT (the hot hull's narrowing of the Band),
## CAUSE_OUT_OF_BAND (the Residual outside the Band). Each is judged with the
## Residual at its fullest, so none comes and goes with the beats; worn and
## hot by what the steadiness would be without that cause. Empty when steady,
## and while the plasma is lost.
func causes(wobble: Vector2, hull_heat_share: float) -> Array[StringName]:
	var named: Array[StringName] = []
	if _lost:
		return named
	var reach := residual_reach(_counter[ACTIVE], wobble)
	var band := _band_of(_head_wear, hull_heat_share)
	var steadiness := _steadiness(_head_wear, maxf(0.0, reach - band))
	var unworn := _steadiness(0.0, maxf(0.0, reach - _band_of(0.0, hull_heat_share)))
	var cool := _steadiness(_head_wear, maxf(0.0, reach - _band_of(_head_wear, 0.0)))
	if unworn - steadiness > _CAUSE_TELLS:
		named.append(CAUSE_WORN)
	if cool - steadiness > _CAUSE_TELLS:
		named.append(CAUSE_HOT)
	if reach > band:
		named.append(CAUSE_OUT_OF_BAND)
	return named


## True while the Residual ACTIVE leaves of `wobble`, at its fullest, is
## outside the Band.
func out_of_band(wobble: Vector2) -> bool:
	return not _lost and residual_reach(_counter[ACTIVE], wobble) > _band


## How far the Residual ACTIVE leaves of `wobble` reaches outside the Band, 0
## (inside) to 1 (the Head grinding at its roughest) and above.
func out_share(wobble: Vector2) -> float:
	return maxf(0.0, residual_reach(_counter[ACTIVE], wobble) - _band) / _ROUGH_RESIDUAL


## Wear on the Head, 0 (none) to 1.
func head_wear() -> float:
	return _head_wear


## True once the plasma has been lost. It stays lost until relit.
func lost() -> bool:
	return _lost


## Why the plasma went out: &"disrupted" (a Residual far outside the Band on
## a badly worn Head), &"worn_through" (the Residual wore the Head through),
## &"scenario" (a Scenario began with it lost) or &"debug" (the debug menu);
## &"" while it holds, and again once relit.
func lost_by() -> StringName:
	return _lost_by


## Extra heat per second from the Head's grinding, while the Residual is
## outside the Band.
func grind_heat() -> float:
	return _roughness * _GRIND_HEAT


## How hard the Head's grinding is shuddering the vessel now, in m/s^2.
func shudder() -> float:
	return _roughness * _SHUDDER_ACCELERATION


## Which way the shudder is jolting now, -1 to 1: shudder() times this is its
## jolt along the Bore toward the Head.
func shudder_phase() -> float:
	return cos(TAU * _SHUDDER_HZ * _time)

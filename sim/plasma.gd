## The Head's plasma and the Shift. The load on the Head excites the plasma
## into a wobble whose frequency rises with the hardness of the Medium being
## cut; the Reactor holds it steady by driving an opposing wave at the
## frequency it is tuned to. A Shift retunes it; a poor one grinds (a heat
## spike, a lurch, wear on the Head); on a badly worn Head a rough one can
## disrupt the plasma, and one that wears the Head through loses it. A lost plasma can be struck again by a relight, paid for from the
## emergency store; the odds fall with the Head's wear. Owned by DiveSimulation, which tends it once a step and answers for
## it through its own queries (plasma_stability(), shift_due(), head_wear()
## ...). Knows nothing of the layout or the Stations: the wobble's frequency
## now and everything else it needs are handed in.
class_name Plasma
extends RefCounted

## Frequency of the wobble per root of hardness, in hertz (a frequency a crew
## can see on a screen, not a real plasma mode). Tuned for play (ADR 0001).
const _PLASMA_HZ_PER_ROOT_HARDNESS := 0.8
## How far the tuning may be from the wobble, as a share of its frequency, and
## still hold the plasma: beyond it a Shift is due. A Shift this far off
## matches 1/e. Tuned for play (ADR 0001).
const _SHIFT_TOLERANCE := 0.12
## Mistuning (share of the wobble's frequency) at which the plasma, and so the
## Reactor's output, is half as steady. Tuned for play (ADR 0001).
const _MISTUNING_HALF := 0.4
## Seconds from crossing a Boundary in which a Shift loses nothing to lateness.
const _SHIFT_WINDOW_S := 10.0
## Seconds after the window closes over which a late Shift's grade falls to
## 1/e. Tuned for play (ADR 0001).
const _SHIFT_LATE_S := 4.0
## Seconds after the window closes at which the Reactor's autopilot makes the
## Shift itself: on frequency, but late, so poorly. Tuned for play (ADR 0001).
const _AUTOPILOT_LATE_S := 6.0
## Grade at or above which a Shift is clean and passes smoothly.
const _CLEAN_SHIFT_GRADE := 0.8
## What a poor Shift costs at its roughest (roughness 1; a Shift just short of
## clean is barely rough). The heat spike's heat per second at its peak and
## the seconds it takes to fade to 1/e; the lurch's jolt along the Bore in
## m/s^2 at its peak, how fast it shudders and how soon it fades; the wear on
## the Head. Tuned for play (ADR 0001): left to the autopilot, the way down
## through two Boundaries survives even with the hull hot, but a third poor
## Shift with the hull hot (or a few more with it cool) loses the plasma.
const _SHIFT_SPIKE_HEAT := 2.0
const _SHIFT_SPIKE_S := 1.5
const _LURCH_ACCELERATION := 14.0
const _LURCH_HZ := 3.0
const _LURCH_S := 0.4
const _SHIFT_WEAR := 0.3
## How much worse a poor Shift wears the Head with the hull at the temperature
## it can bear than with it as cool as the Medium around it. Bad conditions.
const _HOT_SHIFT_WEAR := 1.0
## How much a fully worn Head unsteadies the plasma even when tuned, so the
## Reactor delivers less power at the same setting.
const _WEAR_UNSTEADINESS := 0.3
## How much a fully worn Head narrows the Shift: the window, how far off the
## wobble a Shift may be, and how soon lateness tells, all shrink by this
## share. A worn Head is less forgiving. Tuned for play (ADR 0001).
const _WEAR_NARROWING := 0.5
## A poor Shift on a badly worn Head can disrupt the plasma: it is lost when
## the Shift's roughness times the wear already on the Head reaches this. The
## Head takes only the Shift's own wear, so it may be lost well short of worn
## through. A fresh Head never loses it to one Shift; a badly worn one can
## lose it to any rough one. Tuned for play (ADR 0001).
const _DISRUPTION := 0.5
## A relight: the energy of the pulse that strikes the plasma again, in the
## units of set_power() times seconds, and the chance it takes on a fresh Head
## and on one worn through (between, it falls with the wear). Real basis: a
## tokamak cannot restart itself; striking a plasma takes a large pulse of
## stored energy, and a worn wall fouls it with impurities that can stop it
## taking. Tuned for play (ADR 0001): a healthy Head almost always relights.
const _RELIGHT_PULSE := 40.0
const _RELIGHT_FRESH := 0.95
const _RELIGHT_WORN_THROUGH := 0.4

## How steady the plasma is, 0 (lost) to 1 (steady). The Reactor's output
## scales with it.
var _stability := 1.0
## The frequency the Reactor is tuned to hold the plasma at, in hertz.
var _tuning := 0.0
## Seconds the plasma has been mistuned (a Shift due), 0 while tuned.
var _mistuned_for := 0.0
## A Shift asked for since the last step (its frequency), or NAN.
var _shift_asked := NAN
## Wear on the Head from poor Shifts, 0 (none) to 1 (the plasma is lost).
var _head_wear := 0.0
## True once the plasma has gone out. It stays out.
var _lost := false
## Extra heat per second from the last poor Shift, fading.
var _heat_spike := 0.0
## The last poor Shift's lurch: its peak jolt in m/s^2 and seconds since.
var _lurch_peak := 0.0
var _lurch_age := 0.0


## Starts steady, tuned to `frequency` in hertz.
func _init(frequency: float) -> void:
	_tuning = frequency


## Energy the pulse that relights the plasma takes from the emergency store.
func relight_cost() -> float:
	return _RELIGHT_PULSE


## The chance a relight strikes the plasma on this Head, 0 to 1: high on a
## fresh Head, falling with its wear.
func relight_chance() -> float:
	return lerpf(_RELIGHT_FRESH, _RELIGHT_WORN_THROUGH, _head_wear)


## Tries to strike the lost plasma again, its pulse already paid for. `roll`
## (0 to 1, uniformly random) below relight_chance() lights it, tuned to the
## wobble at `target` hertz so it holds at once. The Head keeps its wear.
## Returns whether it lit; false, and nothing changed, if it was not lost.
func relight(target: float, roll: float) -> bool:
	if not _lost or roll >= relight_chance():
		return false
	_lost = false
	_tuning = target
	_mistuned_for = 0.0
	_shift_asked = NAN
	_stability = 1.0 - _WEAR_UNSTEADINESS * _head_wear
	return true


## Debug only (DiveSimulation's debug commands): sets the Head's wear, 0 to 1.
## It does not lose the plasma: only a poor Shift does that.
func debug_set_wear(wear: float) -> void:
	_head_wear = clampf(wear, 0.0, 1.0)


## Debug only: the plasma goes out, as a Shift that loses it would leave it,
## by the same path (_lose()), raising &"plasma_lost" into `events`.
func debug_lose(events: Array[Dictionary], depth: float, distance: float) -> void:
	_lose(events, depth, distance)
	_stability = 0.0
	_shift_asked = NAN


## The plasma goes out and stays out. Raises &"plasma_lost" into `events`,
## placed at `depth` and `distance`.
func _lose(events: Array[Dictionary], depth: float, distance: float) -> void:
	_lost = true
	events.append({type = &"plasma_lost", depth = depth, distance = distance})


## Debug only: retunes the Reactor well wide of a wobble at `target` hertz,
## so a Shift is due now with its window just opened.
func debug_mistune(target: float) -> void:
	if _lost:
		return
	_tuning = target * (1.0 + 2.0 * _SHIFT_TOLERANCE)
	_mistuned_for = 0.0


## The frequency, in hertz, of the wobble cutting this Medium excites.
static func frequency_in(medium: Medium) -> float:
	return _PLASMA_HZ_PER_ROOT_HARDNESS * sqrt(medium.hardness)


## Asks for a Shift to `frequency` in hertz, made on the next tend().
func ask_shift(frequency: float) -> void:
	_shift_asked = maxf(frequency, 0.0)


## Once a step of dt seconds, before the power is shared, with the wobble at
## `target` hertz: times the mistuned plasma, takes a Shift asked for, lets
## the autopilot make an overdue one when the Reactor is unattended, and sets
## how steady the plasma is. `hull_heat_share` (0 cool to 1 as hot as the hull
## can bear) makes a poor Shift wear the Head harder. Raises &"shift_result"
## and &"plasma_lost" into `events`, placed at `depth` and `distance`.
func tend(dt: float, target: float, reactor_attended: bool, hull_heat_share: float,
		events: Array[Dictionary], depth: float, distance: float) -> void:
	_mistuned_for = _mistuned_for + dt if due(target) else 0.0
	_lurch_age += dt
	_heat_spike *= exp(-dt / _SHIFT_SPIKE_S)
	if _lost:
		_shift_asked = NAN
		_stability = 0.0
		return
	if not is_nan(_shift_asked):
		_make_shift(_shift_asked, false, target, hull_heat_share, events, depth, distance)
		_shift_asked = NAN
	if due(target) and not reactor_attended \
			and _mistuned_for >= window_length() + _AUTOPILOT_LATE_S:
		_make_shift(target, true, target, hull_heat_share, events, depth, distance)
	if _lost:
		_stability = 0.0
		return
	_stability = (1.0 - _WEAR_UNSTEADINESS * _head_wear) \
			/ (1.0 + mistuning(target) / _MISTUNING_HALF)


## A Boundary has been crossed: the load on the Head has changed, so the
## wobble has too, and a new window for the Shift opens.
func open_window() -> void:
	_mistuned_for = 0.0


## How steady the plasma is, 0 (lost) to 1 (steady).
func stability() -> float:
	return _stability


## The frequency, in hertz, the Reactor is tuned to hold the plasma at.
func tuning() -> float:
	return _tuning


## True while the tuning no longer holds a wobble at `target` hertz.
func due(target: float) -> bool:
	return mistuning(target) > _SHIFT_TOLERANCE


## Seconds left in the window in which a due Shift loses nothing to lateness;
## 0 when no Shift is due or the window has closed.
func window(target: float) -> float:
	return maxf(0.0, window_length() - _mistuned_for) if due(target) else 0.0


## Seconds the window for a Shift stays open on this Head: narrower the more
## worn it is.
func window_length() -> float:
	return _SHIFT_WINDOW_S * _narrowing()


## How far a due Shift has gone toward the autopilot making it, 0 (just due)
## to 1 (the autopilot's moment). Above 1 past it.
func overdue_share() -> float:
	return _mistuned_for / (window_length() + _AUTOPILOT_LATE_S)


## How far the tuning is from a wobble at `target` hertz, as a share of it.
func mistuning(target: float) -> float:
	return absf(_tuning - target) / target


## Wear on the Head from poor Shifts, 0 (none) to 1.
func head_wear() -> float:
	return _head_wear


## True once the plasma has been lost. It stays lost.
func lost() -> bool:
	return _lost


## Extra heat per second from the last poor Shift's grinding, fading.
func heat_spike() -> float:
	return _heat_spike


## How hard a poor Shift's lurch is jolting the vessel now, in m/s^2.
func lurch() -> float:
	return _lurch_peak * exp(-_lurch_age / _LURCH_S)


## Which way the lurch is shuddering now, -1 to 1: lurch() times this is its
## jolt along the Bore toward the Head.
func shudder() -> float:
	return cos(TAU * _LURCH_HZ * _lurch_age)


## How closely a Shift to `frequency` hertz would match a wobble at `target`
## hertz on this Head, 1 (exactly) falling toward 0 the further off it is. It
## is the match a Shift is graded on, before any lateness: a worn Head reads
## the same dial as a poorer match.
func match_to(frequency: float, target: float) -> float:
	var error := absf(frequency - target) / target
	return exp(-pow(error / (_SHIFT_TOLERANCE * _narrowing()), 2.0))


## How much of a fresh Head's forgiveness in a Shift this one keeps, 1
## (fresh) down to 1 - _WEAR_NARROWING (worn through).
func _narrowing() -> float:
	return 1.0 - _WEAR_NARROWING * _head_wear


## Makes the Shift to `frequency` and grades it: how closely it matches the
## wobble at `target`, times how late it came after the window. A worn Head
## grades both harsher.
func _make_shift(frequency: float, by_autopilot: bool, target: float, hull_heat_share: float,
		events: Array[Dictionary], depth: float, distance: float) -> void:
	var narrowing := _narrowing()
	var matched := match_to(frequency, target)
	var late := maxf(0.0, _mistuned_for - window_length()) if due(target) else 0.0
	var grade := matched * exp(-late / (_SHIFT_LATE_S * narrowing))
	_tuning = frequency
	if not due(target):
		_mistuned_for = 0.0
	# A poor Shift grinds: the rougher, the bigger the heat spike, the harder
	# the lurch and the more wear on the Head. A clean one does nothing at all.
	var roughness := clampf((_CLEAN_SHIFT_GRADE - grade) / _CLEAN_SHIFT_GRADE, 0.0, 1.0)
	var wear := minf(roughness * _SHIFT_WEAR * (1.0 + _HOT_SHIFT_WEAR * hull_heat_share),
			1.0 - _head_wear)
	# Two ways a poor Shift loses the plasma: on a badly worn Head a rough
	# enough one disrupts it, and one that wears the Head through loses it.
	# A clean Shift does neither, whatever the wear.
	var disrupted := roughness * _head_wear >= _DISRUPTION
	var worn_through := roughness > 0.0 and _head_wear + wear >= 1.0
	if roughness > 0.0:
		_heat_spike += roughness * _SHIFT_SPIKE_HEAT
		_lurch_peak = roughness * _LURCH_ACCELERATION
		_lurch_age = 0.0
		_head_wear += wear
	events.append({type = &"shift_result", grade = grade,
			clean = roughness <= 0.0, late = late, autopilot = by_autopilot, wear = wear})
	if roughness > 0.0 and (disrupted or worn_through):
		_lose(events, depth, distance)

## The vessel's heat: what everything drawing power makes, where Thermal sends
## it (into the Column or outward), and the hull it passes through on the way
## out: the hull's temperature and the wear heat does it. Owned by
## DiveSimulation, which feeds it each step and answers for it through its own
## queries (heat_produced(), vessel_temperature(), vessel_wear() ...). Knows
## nothing of the layout, the path or the Stations: whatever it needs about
## them is handed in.
class_name Heat
extends RefCounted

## Heat made per second for each unit of power drawn. Every system that draws
## power makes heat. Tuned for play (ADR 0001).
const _HEAT_PER_POWER := 1.0
## Heat per metre of Column that halves the quality the Bore Station can
## record. Tuned for play (ADR 0001).
const _COLUMN_COOK_HEAT_PER_M := 2.0
## How much heat per second the hull sheds into the surrounding Medium for each
## kelvin it is hotter than the Medium. Tuned for play (ADR 0001).
const _HULL_SHED_PER_K := 1.0 / 400.0
## Heat it takes to warm the hull by one kelvin, so the hull warms and cools
## over a minute or so rather than at once. Tuned for play (ADR 0001).
const _HULL_HEAT_PER_K := 0.15
## Hull temperature in kelvin above which heat damages the vessel. Tuned for
## play (ADR 0001).
const _HULL_DAMAGE_K := 600.0
## How far below _HULL_DAMAGE_K the hull's own temperature brings on the heat
## warning. Tuned for play (ADR 0001).
const _HULL_WARNING_MARGIN_K := 50.0
## How much warmer the ground gets per metre of depth, in kelvin. Earth's crust
## warms by about 0.025 K/m; tuned for play (ADR 0001).
const _GEOTHERMAL_K_PER_M := 0.03
## Wear per second for each kelvin the hull is above _HULL_DAMAGE_K, at the
## surface. Tuned for play (ADR 0001).
const _WEAR_PER_K_S := 1.0e-5
## Depth in metres at which the rock's pressure has doubled the stress on the
## hull, and so how fast it creeps when overheated. Creep is driven by stress
## as well as heat, and the rock's weight grows with depth (about 27 MPa per
## km in Earth's crust). Tuned for play (ADR 0001).
const _CREEP_STRESS_DEPTH_M := 1000.0
## With the Head dark, how much hotter than the surrounding rock the heat
## soaking into the hull is, in kelvin: the melt the Head left round the
## vessel and in the sealed tunnel behind, and the rock the dive heated, with
## no pumps running to carry it away. Above the hull's rated temperature even
## near the surface, so a stranding always runs against a clock; deeper,
## hotter rock makes it shorter. Tuned for play (ADR 0001). Real basis: a melt
## front sits near the rock's melting point, far above the far rock.
const _DARK_SOAK_K := 300.0
## Heat per second Thermal's pumps carry from the hull into the Column with
## the Head dark, running at full on the emergency store. Enough to hold a
## hull below its rated temperature for a while at moderate depth, not
## forever. Tuned for play (ADR 0001). Real basis: a heat pump moves heat
## into the cooler Column, as Thermal does while the Head runs.
const _DARK_COOLING := 0.25
## Longest stranding clock worked out, in seconds; a hull that would last
## longer reads as lasting for ever (INF). Not a tuned constant: the limit of
## time_to_fail()'s search, about eleven days, far beyond any rescue or dive,
## so it changes nothing in play.
const _LONGEST_CLOCK_S := 1.0e6

## Heat made in the last step, per second.
var _produced := 0.0
## Heat sent into the Column in the last step, per second.
var _to_column := 0.0
## The hull's temperature in kelvin. Heat sent outward passes through it.
var _temperature := 0.0
## The temperature the hull is heading for at the heat now sent outward.
var _settling_at := 0.0
## Damage done to the vessel by heat, 0 (none) to 1.
var _wear := 0.0
## Wear per second in the last step: how fast the overheated hull creeps.
var _creep_rate := 0.0
## The stress on the hull in the last step, 1 at the surface, growing with
## depth under the rock's pressure.
var _stress := 1.0


## Starts with the hull at the temperature of its surroundings, in kelvin.
func _init(surroundings_k: float) -> void:
	_temperature = surroundings_k
	_settling_at = surroundings_k


## Temperature in kelvin of the Medium around the vessel at a depth: the
## Medium's own temperature plus the planet's warming with depth.
static func surroundings(medium: Medium, depth: float) -> float:
	return medium.temperature + _GEOTHERMAL_K_PER_M * depth


## One step of dt seconds. Every system that draws power makes heat
## (`power_drawn`), plus `spike`, extra heat per second such as a poor Shift's
## grinding. Heat reaches the Column only as far as Thermal's pumps are
## powered (`split` times `thermal_supplied`); the rest goes out through the
## hull into surroundings at `surroundings_k`. The overheated hull creeps
## faster at greater `depth`, under the rock's pressure.
func step(power_drawn: float, spike: float, split: float, thermal_supplied: float,
		surroundings_k: float, depth: float, dt: float) -> void:
	_produced = power_drawn * _HEAT_PER_POWER + spike
	_to_column = _produced * split * thermal_supplied
	_shed_outward(_produced - _to_column, surroundings_k, dt)
	_creep(depth, dt)


## One step of dt seconds with the Head dark: heat soaks into the hull from
## the melt and rock round it (soak_temperature()). Thermal's pumps, running
## on the emergency store, carry `cooling` (0 to 1, the share of their full
## flow) of it into the Column. Nothing makes heat but `dumped`, power (in the
## units of set_power()) the emergency store discharges into the hull itself,
## as self-destruct does: stored energy through a resistive load all becomes
## heat. The overheated hull creeps as it does under way, faster at greater
## `depth`.
func soak(surroundings_k: float, cooling: float, depth: float, dt: float,
		dumped := 0.0) -> void:
	_produced = dumped * _HEAT_PER_POWER
	_to_column = cooling * _DARK_COOLING
	_settling_at = _soak_settling(surroundings_k, cooling, dumped)
	var toward := exp(-dt * _HULL_SHED_PER_K / _HULL_HEAT_PER_K)
	_temperature = _settling_at + (_temperature - _settling_at) * toward
	_creep(depth, dt)


## The temperature in kelvin heat soaks into the hull at with the Head dark,
## among surroundings at `surroundings_k`.
static func soak_temperature(surroundings_k: float) -> float:
	return surroundings_k + _DARK_SOAK_K


## Seconds until the hull fails with the Head dark from now, at `depth` among
## surroundings at `surroundings_k`: heat soaks in, Thermal's pumps carry
## `cooling` (0 to 1) of their full flow away, and the store dumps `dumped`
## power into the hull (as soak()), for `cooled_for` seconds while the store
## lasts, and then both stop. INF if it would bear the heat for ever. The wear by any time is
## exact (_soaked_wear()); the time it reaches failure is found by bisection
## up to _LONGEST_CLOCK_S.
func time_to_fail(surroundings_k: float, depth: float, cooling: float,
		cooled_for: float, dumped := 0.0) -> float:
	var left := 1.0 - _wear
	if left <= 0.0:
		return 0.0
	var stress := _stress_at(depth)
	var cooled_to := _soak_settling(surroundings_k, cooling, dumped)
	var dark_to := _soak_settling(surroundings_k, 0.0)
	var wear_at := func(t: float) -> float:
		var first := minf(t, cooled_for)
		var wear := _soaked_wear(_temperature, cooled_to, first, stress)
		if t > cooled_for:
			var after := _soaked_temperature(_temperature, cooled_to, first)
			wear += _soaked_wear(after, dark_to, t - cooled_for, stress)
		return wear
	if wear_at.call(_LONGEST_CLOCK_S) < left:
		return INF
	var low := 0.0
	var high := _LONGEST_CLOCK_S
	for i in 60:
		var middle := (low + high) / 2.0
		if wear_at.call(middle) < left:
			low = middle
		else:
			high = middle
	return high


## Debug only (DiveSimulation's debug commands): sets the hull's wear, 0 to 1.
func debug_set_wear(wear: float) -> void:
	_wear = clampf(wear, 0.0, 1.0)


## Heat made in the last step, per second.
func produced() -> float:
	return _produced


## Heat sent into the Column in the last step, per second.
func to_column() -> float:
	return _to_column


## Heat sent outward through the hull in the last step, per second.
func outward() -> float:
	return _produced - _to_column


## The hull's temperature in kelvin.
func vessel_temperature() -> float:
	return _temperature


## Damage heat has done to the vessel so far, 0 (none) to 1.
func vessel_wear() -> float:
	return _wear


## Wear per second in the last step; 0 while the hull bears its heat.
func creep_rate() -> float:
	return _creep_rate


## True while heat is wearing the hull: it is hotter than it can bear.
func taking_damage() -> bool:
	return _creep_rate > 0.0


## The stress on the hull in the last step: 1 at the surface, greater deeper
## down where the rock presses harder.
func stress() -> float:
	return _stress


## True once heat has worn the hull through.
func failed() -> bool:
	return _wear >= 1.0


## True while the hull is close to the temperature at which heat damages it,
## or the heat now sent outward will take it past that if nothing changes.
func warning() -> bool:
	return _temperature >= warning_temperature() or _settling_at > damage_temperature()


## Hull temperature in kelvin at which warning() comes on regardless of where
## the hull is heading.
func warning_temperature() -> float:
	return _HULL_DAMAGE_K - _HULL_WARNING_MARGIN_K


## Hull temperature in kelvin above which heat wears the vessel.
func damage_temperature() -> float:
	return _HULL_DAMAGE_K


## How hot the hull is, from as cool as surroundings at `surroundings_k` (0)
## to the temperature it can bear (1).
func hull_heat_share(surroundings_k: float) -> float:
	return clampf((_temperature - surroundings_k) / (_HULL_DAMAGE_K - surroundings_k), 0.0, 1.0)


## How much of the Column's record survives the heat sent into it, 0 to 1, at
## this speed in metres per second. What spoils it is the heat each metre of
## Column takes up: the same heat spread over more Column (moving faster)
## cooks each metre less.
func unheated_share(speed: float) -> float:
	if _to_column <= 0.0:
		return 1.0
	if speed <= 0.0:
		return 0.0
	var heat_per_metre := _to_column / speed
	return 1.0 / (1.0 + heat_per_metre / _COLUMN_COOK_HEAT_PER_M)


## Passes heat outward through the hull for dt seconds. The hull settles toward
## the temperature at which it sheds that heat into the Medium: never cooler
## than the Medium itself, so hot rock heats it whatever the power.
func _shed_outward(heat: float, surroundings_k: float, dt: float) -> void:
	_settling_at = surroundings_k + heat / _HULL_SHED_PER_K
	var toward := exp(-dt * _HULL_SHED_PER_K / _HULL_HEAT_PER_K)
	_temperature = _settling_at + (_temperature - _settling_at) * toward


## Wears the hull for dt seconds at `depth`. Creep: none below the temperature
## the hull bears; above it, faster the further over and the greater the
## stress, which the rock's pressure raises with depth.
func _creep(depth: float, dt: float) -> void:
	var overheat := _temperature - _HULL_DAMAGE_K
	_stress = _stress_at(depth)
	_creep_rate = _WEAR_PER_K_S * overheat * _stress if overheat > 0.0 else 0.0
	_wear = minf(1.0, _wear + _creep_rate * dt)


## The stress on the hull at `depth`: 1 at the surface, growing with the
## rock's pressure.
static func _stress_at(depth: float) -> float:
	return 1.0 + maxf(depth, 0.0) / _CREEP_STRESS_DEPTH_M


## Where the hull settles with the Head dark: the soak temperature, less what
## Thermal's pumps carry away at `cooling` (0 to 1), plus the heat of power
## `dumped` into it from the store.
static func _soak_settling(surroundings_k: float, cooling: float, dumped := 0.0) -> float:
	return soak_temperature(surroundings_k) \
			+ (dumped * _HEAT_PER_POWER - cooling * _DARK_COOLING) / _HULL_SHED_PER_K


## The hull's temperature `seconds` after it was at `from_k`, settling toward
## `toward_k`.
static func _soaked_temperature(from_k: float, toward_k: float, seconds: float) -> float:
	return toward_k + (from_k - toward_k) * exp(-seconds / (_HULL_HEAT_PER_K / _HULL_SHED_PER_K))


## The wear creep does over `seconds` to a hull settling from `from_k` toward
## `toward_k` under `stress`: the creep rule of _creep(), summed exactly over
## the time the hull spends above its rated temperature.
static func _soaked_wear(from_k: float, toward_k: float, seconds: float, stress: float) -> float:
	if seconds <= 0.0:
		return 0.0
	var tau := _HULL_HEAT_PER_K / _HULL_SHED_PER_K
	var limit := _HULL_DAMAGE_K
	var over := from_k - toward_k
	# The hull moves steadily toward toward_k, so it is above the limit over
	# one span of time: [start, end].
	var start := 0.0
	var end := seconds
	if from_k < limit:
		if toward_k <= limit:
			return 0.0
		start = tau * log((toward_k - from_k) / (toward_k - limit))
	elif toward_k < limit:
		end = minf(seconds, tau * log((from_k - toward_k) / (limit - toward_k)))
	if end <= start:
		return 0.0
	# Integral of (T - limit) dt, where T = toward_k + over * e^(-t / tau).
	var heat_time := (toward_k - limit) * (end - start) \
			+ over * tau * (exp(-start / tau) - exp(-end / tau))
	return _WEAR_PER_K_S * stress * heat_time

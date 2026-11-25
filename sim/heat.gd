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
	var stress := 1.0 + maxf(depth, 0.0) / _CREEP_STRESS_DEPTH_M
	_creep_rate = _WEAR_PER_K_S * overheat * stress if overheat > 0.0 else 0.0
	_wear = minf(1.0, _wear + _creep_rate * dt)

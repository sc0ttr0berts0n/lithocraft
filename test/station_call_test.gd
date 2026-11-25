# Unattended Stations, Station calls and the time rate, tested at the
# simulation's interface. Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: rock strong enough that the grip waves never slip.
func _rock() -> Medium:
	return Medium.new(&"rock", 2.0, 2.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _soft() -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _hard() -> Medium:
	return Medium.new(&"hard", 4.0, 3.0, 0.3, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


## Hard rock that fills the tunnel in behind the Tail.
func _dense() -> Medium:
	return Medium.new(&"dense", 4.0, 3.0, 0.01, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


func _one_boundary(at := 20.0, below: Medium = null) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [at, below if below else _hard()]]))
	sim.set_power(0.5)
	return sim


## Advances until an event of this type is raised (or the time runs out) and
## returns it, or an empty Dictionary. Every event seen is kept in `seen`.
func _run_until(sim: DiveSimulation, type: StringName, seconds := 600.0,
		seen: Array = [], step := 0.1) -> Dictionary:
	for i in int(seconds / step):
		sim.advance(step)
		var events := sim.take_events()
		seen.append_array(events)
		for event in events:
			if event.type == type:
				return event
	return {}


func _calls(events: Array, station: StringName) -> Array:
	return events.filter(func(e: Dictionary) -> bool:
		return e.type == &"station_call" and e.station == station)


# --- Unattended Stations ----------------------------------------------------

func test_every_station_starts_unattended_and_can_be_attended() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_rock()))
	for station in DiveSimulation.STATIONS:
		assert_bool(sim.attended(station)).is_false()

	sim.set_attended(DiveSimulation.STATION_THERMAL, true)

	assert_bool(sim.attended(DiveSimulation.STATION_THERMAL)).is_true()
	assert_bool(sim.attended(DiveSimulation.STATION_REACTOR)).is_false()


func test_unattended_stations_hold_their_settings_through_steady_conditions() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_rock()))
	sim.set_power(0.4)
	sim.set_heat_split(0.3)
	sim.set_pitch(45.0)
	sim.set_heading(30.0)
	sim.set_upload_priority(DiveSimulation.UPLOAD_NEWEST_FIRST)
	for i in 600:
		sim.advance(1.0)
		assert_bool(sim.heat_warning()).is_false()
	var speed_before := sim.speed()
	for i in 600:
		sim.advance(1.0)

	assert_float(sim.power()).is_equal(0.4)
	assert_float(sim.heat_split()).is_equal(0.3)
	assert_float(sim.pitch()).is_equal_approx(45.0, 0.5)
	assert_float(sim.heading_degrees()).is_equal_approx(30.0, 0.5)
	assert_str(String(sim.upload_priority())).is_equal(String(DiveSimulation.UPLOAD_NEWEST_FIRST))
	assert_float(sim.speed()).is_equal_approx(speed_before, speed_before * 0.01)
	assert_float(sim.vessel_wear()).is_equal(0.0)
	assert_float(sim.head_wear()).is_equal(0.0)


## Full power, all heat outward: the hull heads for damage.
func _overheating(attended: bool) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(_rock()))
	sim.set_power(1.0)
	sim.set_attended(DiveSimulation.STATION_THERMAL, attended)
	return sim


func test_unattended_thermal_steadies_a_warning_hull_by_sending_heat_into_the_column() -> void:
	var left := _overheating(false)
	var held := _overheating(true)
	for i in 1200:
		left.advance(1.0)
		held.advance(1.0)

	assert_float(held.heat_split()).is_equal(0.0)
	assert_float(left.heat_split()).is_greater(0.0)
	assert_float(left.vessel_wear()).is_less(held.vessel_wear())


func test_unattended_thermal_is_slow_to_answer_a_sudden_heat() -> void:
	var sim := _overheating(false)
	var warned := false
	while not warned:
		sim.advance(0.5)
		warned = sim.heat_warning()
	sim.advance(1.0)

	# One second after the warning it has barely begun to move the split.
	assert_float(sim.heat_split()).is_less(0.1)


## Crosses the one Boundary with the Reactor attended or not; if attended,
## the crew Shifts to the plasma's frequency within the window. Returns the
## Shift result.
func _shift_with_reactor(attended: bool) -> Dictionary:
	var sim := _one_boundary()
	sim.set_attended(DiveSimulation.STATION_REACTOR, attended)
	_run_until(sim, &"boundary_crossed")
	if attended:
		sim.advance(2.0)
		sim.shift(sim.plasma_frequency())
	return _run_until(sim, &"shift_result")


func test_an_unattended_reactor_grades_a_shift_worse_than_an_attended_one() -> void:
	var unattended := _shift_with_reactor(false)
	var attended := _shift_with_reactor(true)

	assert_bool(unattended.autopilot).is_true()
	assert_bool(attended.autopilot).is_false()
	assert_float(unattended.grade).is_less(attended.grade)


func test_an_attended_reactor_leaves_the_shift_to_the_crew_until_they_walk_away() -> void:
	var sim := _one_boundary()
	sim.set_attended(DiveSimulation.STATION_REACTOR, true)
	_run_until(sim, &"boundary_crossed")

	assert_dict(_run_until(sim, &"shift_result", 120.0)).is_empty()
	assert_bool(sim.shift_due()).is_true()

	sim.set_attended(DiveSimulation.STATION_REACTOR, false)
	var result := _run_until(sim, &"shift_result", 5.0)
	assert_bool(result.autopilot).is_true()
	assert_bool(result.clean).is_false()


# --- The time rate ----------------------------------------------------------

func test_a_raised_time_rate_runs_more_simulated_time_per_step() -> void:
	var normal := DiveSimulation.new(MediumLayout.uniform(_rock()))
	var fast := DiveSimulation.new(MediumLayout.uniform(_rock()))
	for sim in [normal, fast]:
		sim.set_power(0.5)
	fast.set_time_rate(fast.max_time_rate())
	for i in 600:
		normal.advance(1.0 / 60.0)
		fast.advance(1.0 / 60.0)

	assert_float(fast.max_time_rate()).is_greater(1.0)
	assert_float(fast.time_rate()).is_equal(fast.max_time_rate())
	assert_float(fast.distance()).is_greater(normal.distance() * fast.max_time_rate() * 0.9)


func test_the_time_rate_is_never_below_normal_nor_above_its_maximum() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_rock()))
	assert_float(sim.time_rate()).is_equal(1.0)

	sim.set_time_rate(0.1)
	assert_float(sim.time_rate()).is_equal(1.0)
	sim.set_time_rate(sim.max_time_rate() * 10.0)
	assert_float(sim.time_rate()).is_equal(sim.max_time_rate())


func test_a_station_call_returns_the_time_rate_to_normal() -> void:
	var sim := _one_boundary(200.0)
	sim.set_time_rate(sim.max_time_rate())
	var seen := []

	var call := _run_until(sim, &"station_call", 600.0, seen, 1.0 / 60.0)

	assert_dict(call).is_not_empty()
	assert_str(String(call.station)).is_equal(String(DiveSimulation.STATION_REACTOR))
	assert_float(sim.time_rate()).is_equal(1.0)
	# It drops back the moment the call comes, not after running on fast.
	assert_bool(_types(seen).has(&"boundary_crossed")).is_false()
	assert_bool(sim.shift_due()).is_false()


func test_the_time_rate_can_be_raised_again_after_a_call() -> void:
	var sim := _one_boundary(200.0)
	sim.set_time_rate(sim.max_time_rate())
	_run_until(sim, &"station_call", 600.0, [], 1.0 / 60.0)

	sim.set_time_rate(sim.max_time_rate())
	sim.advance(1.0 / 60.0)

	assert_float(sim.time_rate()).is_equal(sim.max_time_rate())


func _types(events: Array) -> Array:
	return events.map(func(e: Dictionary) -> StringName: return e.type)


# --- Station calls ------------------------------------------------------------

func test_a_quiet_dive_raises_no_calls() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_rock()))
	sim.set_power(0.4)
	var seen := []
	_run_until(sim, &"never", 300.0, seen, 1.0)

	assert_array(_calls(seen, DiveSimulation.STATION_REACTOR)).is_empty()
	for station in DiveSimulation.STATIONS:
		assert_float(sim.call_urgency(station)).is_equal(0.0)


func test_the_reactor_calls_for_a_boundary_ahead_and_more_urgently_for_a_shift_due() -> void:
	var sim := _one_boundary(60.0)
	var approaching := _run_until(sim, &"boundary_approaching")
	sim.advance(0.1)
	var ahead := sim.call_urgency(DiveSimulation.STATION_REACTOR)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("boundary_approaching")
	assert_dict(approaching).is_not_empty()

	_run_until(sim, &"boundary_crossed")
	sim.advance(0.1)
	var due := sim.call_urgency(DiveSimulation.STATION_REACTOR)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("shift_due")

	assert_float(ahead).is_greater(0.0)
	assert_float(due).is_greater(ahead)


func test_urgency_rises_as_a_boundary_nears_and_as_a_shift_goes_late() -> void:
	var sim := _one_boundary(60.0)
	_run_until(sim, &"boundary_approaching")
	sim.advance(0.1)
	var far := sim.call_urgency(DiveSimulation.STATION_REACTOR)
	while sim.depth() < 58.0:
		sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_greater(far)

	_run_until(sim, &"boundary_crossed")
	sim.advance(0.1)
	var early := sim.call_urgency(DiveSimulation.STATION_REACTOR)
	for i in 80:
		sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_greater(early)


func test_a_call_is_announced_once_when_it_begins() -> void:
	var sim := _one_boundary(60.0)
	var seen := []
	_run_until(sim, &"boundary_crossed", 600.0, seen)
	for i in 20:
		sim.advance(0.1)
		seen.append_array(sim.take_events())

	var reactor := _calls(seen, DiveSimulation.STATION_REACTOR)
	assert_array(reactor.map(func(e: Dictionary) -> StringName: return e.reason)) \
			.is_equal([&"boundary_approaching", &"shift_due"])
	assert_float(reactor[1].urgency).is_greater(0.0)


func test_thermal_calls_while_the_hull_warns() -> void:
	var sim := _overheating(true)
	var seen := []
	while not sim.heat_warning():
		sim.advance(0.5)
		seen.append_array(sim.take_events())
	sim.advance(0.5)
	seen.append_array(sim.take_events())

	assert_array(_calls(seen, DiveSimulation.STATION_THERMAL)).is_not_empty()
	assert_str(String(sim.call_reason(DiveSimulation.STATION_THERMAL))).is_equal("heat_warning")
	assert_float(sim.call_urgency(DiveSimulation.STATION_THERMAL)).is_greater(0.0)


func test_a_starved_station_calls() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_rock()))
	sim.set_power(0.5)
	sim.set_heat_split(1.0)
	sim.set_quiet_ship(true)  # The Head idles, so the Reactor runs short.
	for i in 60:
		sim.advance(0.5)

	assert_float(sim.thermal_supplied()).is_less(1.0)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_THERMAL))).is_equal("starved")


func test_the_bore_station_calls_before_the_tunnel_seals() -> void:
	var sim := _one_boundary(30.0, _dense())
	_run_until(sim, &"boundary_crossed")
	sim.advance(0.1)
	var soon := sim.call_urgency(DiveSimulation.STATION_BORE)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_BORE))).is_equal("tunnel_about_to_seal")
	assert_bool(sim.tunnel_sealed()).is_false()
	while sim.distance() < 30.0 + sim.vessel_length() * 0.8:
		sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_BORE)).is_greater(soon)

	_run_until(sim, &"tunnel_sealed")
	sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_BORE)).is_equal(0.0)


func test_the_bore_station_calls_for_a_feature_in_the_column_until_observed() -> void:
	var layout := MediumLayout.uniform(_rock()).with_features([[5.0, ColumnFeature.quartz_vein()]])
	var sim := DiveSimulation.new(layout)
	sim.set_power(0.5)
	while sim.found_features().is_empty():
		sim.advance(0.1)
	sim.advance(0.1)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_BORE))).is_equal("feature_in_column")

	sim.set_observed_feature(sim.features_in_column()[0].id)
	sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_BORE)).is_equal(0.0)

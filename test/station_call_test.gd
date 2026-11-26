# Station calls and the time rate, tested at the
# simulation's interface. Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


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


func _calls(events: Array, station: StringName) -> Array:
	return events.filter(func(e: Dictionary) -> bool:
		return e.type == &"station_call" and e.station == station)


# --- The time rate ----------------------------------------------------------

func test_a_raised_time_rate_runs_more_simulated_time_per_step() -> void:
	var normal := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)))
	var fast := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)))
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
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)))
	assert_float(sim.time_rate()).is_equal(1.0)

	sim.set_time_rate(0.1)
	assert_float(sim.time_rate()).is_equal(1.0)
	sim.set_time_rate(sim.max_time_rate() * 10.0)
	assert_float(sim.time_rate()).is_equal(sim.max_time_rate())


func test_a_station_call_returns_the_time_rate_to_normal() -> void:
	var sim := _one_boundary(200.0)
	sim.set_time_rate(sim.max_time_rate())
	var seen := []

	var call := DiveTestKit.run_until(sim, &"station_call", 600.0, seen, 1.0 / 60.0)

	assert_dict(call).is_not_empty()
	assert_str(String(call.station)).is_equal(String(DiveSimulation.STATION_REACTOR))
	assert_float(sim.time_rate()).is_equal(1.0)
	# It drops back the moment the call comes, not after running on fast.
	assert_bool(DiveTestKit.types(seen).has(&"boundary_crossed")).is_false()
	assert_bool(sim.out_of_band()).is_false()


func test_the_time_rate_cannot_be_raised_while_a_station_is_still_calling() -> void:
	var sim := _one_boundary(200.0)
	sim.set_time_rate(sim.max_time_rate())
	DiveTestKit.run_until(sim, &"station_call", 600.0, [], 1.0 / 60.0)

	sim.set_time_rate(sim.max_time_rate())
	assert_float(sim.time_rate()).is_equal(1.0)
	sim.advance(1.0 / 60.0)
	sim.set_time_rate(sim.max_time_rate())

	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_greater(0.0)
	assert_float(sim.time_rate()).is_equal(1.0)


func test_the_time_rate_can_be_raised_again_once_no_station_calls() -> void:
	var sim := _one_boundary(200.0)
	sim.set_attended(DiveSimulation.STATION_REACTOR, true)
	DiveTestKit.run_until(sim, &"boundary_crossed", 6000.0)
	DiveTestKit.cancel_wobble(sim)
	sim.advance(0.1)
	for station in DiveSimulation.STATIONS:
		assert_float(sim.call_urgency(station)).is_equal(0.0)

	sim.set_time_rate(sim.max_time_rate())
	sim.advance(1.0 / 60.0)

	assert_float(sim.time_rate()).is_equal(sim.max_time_rate())


# --- Station calls ------------------------------------------------------------

func test_a_quiet_dive_raises_no_calls() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)))
	sim.set_power(0.4)
	var seen := []
	DiveTestKit.run_until(sim, &"never", 300.0, seen, 1.0)

	assert_array(_calls(seen, DiveSimulation.STATION_REACTOR)).is_empty()
	for station in DiveSimulation.STATIONS:
		assert_float(sim.call_urgency(station)).is_equal(0.0)


func test_the_reactor_calls_for_a_boundary_ahead_and_more_urgently_for_a_residual_outside_the_band() -> void:
	var sim := _one_boundary(60.0)
	var approaching := DiveTestKit.run_until(sim, &"boundary_approaching")
	sim.advance(0.1)
	var ahead := sim.call_urgency(DiveSimulation.STATION_REACTOR)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("boundary_approaching")
	assert_dict(approaching).is_not_empty()

	DiveTestKit.run_until(sim, &"boundary_crossed")
	sim.advance(0.1)
	var due := sim.call_urgency(DiveSimulation.STATION_REACTOR)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("out_of_band")

	assert_float(ahead).is_greater(0.0)
	assert_float(due).is_greater(ahead)


func test_urgency_rises_as_a_boundary_nears_and_the_further_the_residual_is_outside_the_band() -> void:
	var sim := _one_boundary(60.0)
	DiveTestKit.run_until(sim, &"boundary_approaching")
	sim.advance(0.1)
	var far := sim.call_urgency(DiveSimulation.STATION_REACTOR)
	while sim.depth() < 58.0:
		sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_greater(far)

	# A Residual a little outside the Band calls; one far outside, louder.
	var near := _one_boundary(600.0)
	var wide := _one_boundary(600.0)
	near.advance(0.1)
	wide.advance(0.1)
	DiveTestKit.tune(near, DiveSimulation.CHANNEL_ACTIVE, DiveTestKit.wobble(near) + Vector2(0.0, 1.5 * near.band()))
	DiveTestKit.tune(wide, DiveSimulation.CHANNEL_ACTIVE, DiveTestKit.wobble(wide) + Vector2(0.0, 3.0 * wide.band()))
	near.advance(0.1)
	wide.advance(0.1)
	assert_float(near.call_urgency(DiveSimulation.STATION_REACTOR)).is_greater(0.0)
	assert_float(wide.call_urgency(DiveSimulation.STATION_REACTOR)).is_greater(
			near.call_urgency(DiveSimulation.STATION_REACTOR))


func test_a_call_is_announced_once_when_it_begins() -> void:
	var sim := _one_boundary(60.0)
	var seen := []
	DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, seen)
	for i in 20:
		sim.advance(0.1)
		seen.append_array(sim.take_events())

	var reactor := _calls(seen, DiveSimulation.STATION_REACTOR)
	assert_array(reactor.map(func(e: Dictionary) -> StringName: return e.reason)) \
			.is_equal([&"boundary_approaching", &"out_of_band"])
	assert_float(reactor[1].urgency).is_greater(0.0)


func test_thermal_calls_while_the_hull_warns() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)))
	sim.set_power(1.0)
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
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)))
	sim.set_power(0.5)
	sim.set_heat_split(1.0)
	sim.set_quiet_ship(true)  # The Head idles, so the Reactor runs short.
	for i in 60:
		sim.advance(0.5)

	assert_float(sim.thermal_supplied()).is_less(1.0)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_THERMAL))).is_equal("starved")


func test_the_bore_station_calls_before_the_tunnel_seals() -> void:
	var sim := _one_boundary(30.0, _dense())
	DiveTestKit.run_until(sim, &"boundary_crossed")
	DiveTestKit.cancel_wobble(sim)  # The Reactor's crew sees to the new Wobble.
	sim.advance(0.1)
	var soon := sim.call_urgency(DiveSimulation.STATION_BORE)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_BORE))).is_equal("tunnel_about_to_seal")
	assert_bool(sim.tunnel_sealed()).is_false()
	while sim.distance() < 30.0 + sim.vessel_length() * 0.8:
		sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_BORE)).is_greater(soon)

	DiveTestKit.run_until(sim, &"tunnel_sealed")
	sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_BORE)).is_equal(0.0)


func test_the_bore_station_calls_for_a_feature_in_the_column_until_observed() -> void:
	var layout := MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)).with_features([[5.0, ColumnFeature.quartz_vein()]])
	var sim := DiveSimulation.new(layout)
	sim.set_power(0.5)
	while sim.found_features().is_empty():
		sim.advance(0.1)
	sim.advance(0.1)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_BORE))).is_equal("feature_in_column")

	sim.set_observed_feature(sim.features_in_column()[0].id)
	sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_BORE)).is_equal(0.0)

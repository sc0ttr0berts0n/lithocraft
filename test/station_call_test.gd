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


## Uniform rock with a feature of interest a few metres down, under way at a
## power that raises no other call.
func _with_a_feature() -> DiveSimulation:
	var layout := MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)).with_features([[5.0, ColumnFeature.quartz_vein()]])
	var sim := DiveSimulation.new(layout)
	sim.set_power(0.4)
	return sim


## Under way far above any Boundary, ACTIVE's amplitude off the Wobble's by
## `bands` Bands: outside the Band by that much less one.
func _out_of_band(bands: float) -> DiveSimulation:
	var sim := _one_boundary(600.0)
	sim.advance(0.1)
	_detune(sim, bands)
	sim.advance(0.1)
	return sim


static func _detune(sim: DiveSimulation, bands: float) -> void:
	DiveTestKit.tune(sim, DiveSimulation.CHANNEL_ACTIVE, DiveTestKit.wobble(sim) + Vector2(0.0, bands * sim.band()))


## The Stations whose call sounds now.
static func _sounding(sim: DiveSimulation) -> Array:
	return DiveSimulation.STATIONS.filter(func(station: StringName) -> bool: return sim.call_sounding(station))


## Under way in soft rock above one Boundary into hard rock that a pulse
## carries well, after a Quiet Ship scan, so the scan has a guess of the
## Wobble beyond; STANDBY pretuned against it or left as it starts. At low
## power, so the Boundary is announced well before the crossing.
func _scanned_above_a_boundary(pretuned: bool) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.soft(0.6)], [80.0, DiveTestKit.hard(0.6)]]))
	sim.set_power(0.15)
	DiveTestKit.run(sim, 5.0, 0.1)
	DiveTestKit.quiet_scan(sim, 6)
	if pretuned:
		DiveTestKit.tune(sim, DiveSimulation.CHANNEL_STANDBY, DiveTestKit.wobble_ahead(sim))
	return sim


## Runs until the Reactor calls for the Boundary ahead, or the Boundary is
## crossed first; returns the depth of the Head then and whether it was the
## call.
static func _until_the_boundary_call(sim: DiveSimulation) -> Dictionary:
	for i in 60000:
		sim.advance(0.1)
		var crossed := DiveTestKit.types(sim.take_events()).has(&"boundary_crossed")
		if sim.call_reason(DiveSimulation.STATION_REACTOR) == &"boundary_approaching" or crossed:
			return {depth = sim.depth(), called = not crossed}
	return {depth = sim.depth(), called = false}


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


func test_a_warning_returns_the_time_rate_to_normal() -> void:
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


func test_the_time_rate_cannot_be_raised_while_a_warning_sounds() -> void:
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


# --- Science leaves the time rate alone --------------------------------------

func test_a_feature_entering_the_column_leaves_a_raised_time_rate_as_it_is_and_still_calls_the_bore_station() -> void:
	var sim := _with_a_feature()
	sim.set_time_rate(sim.max_time_rate())
	for i in 6000:
		sim.advance(1.0 / 60.0)
		if sim.call_reason(DiveSimulation.STATION_BORE) == &"feature_in_column":
			break

	assert_str(String(sim.call_reason(DiveSimulation.STATION_BORE))).is_equal("feature_in_column")
	assert_float(sim.call_urgency(DiveSimulation.STATION_BORE)).is_greater(0.0)
	assert_bool(sim.call_sounding(DiveSimulation.STATION_BORE)).is_true()
	assert_bool(sim.call_warns(DiveSimulation.STATION_BORE)).is_false()
	assert_float(sim.time_rate()).is_equal(sim.max_time_rate())
	# Nor does it hold the rate down, unacknowledged.
	sim.set_time_rate(1.0)
	sim.set_time_rate(sim.max_time_rate())
	assert_float(sim.time_rate()).is_equal(sim.max_time_rate())


# --- The master acknowledge ---------------------------------------------------

func test_after_the_acknowledge_no_call_sounds_and_each_acknowledged_call_still_shows() -> void:
	var sim := _with_a_feature()
	while sim.call_reason(DiveSimulation.STATION_BORE) != &"feature_in_column":
		sim.advance(0.1)
	_detune(sim, 1.5)
	sim.advance(0.1)
	assert_array(_sounding(sim)).contains_exactly_in_any_order([DiveSimulation.STATION_REACTOR, DiveSimulation.STATION_BORE])

	sim.acknowledge_calls()
	sim.advance(0.1)

	assert_array(_sounding(sim)).is_empty()
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("out_of_band")
	assert_str(String(sim.call_reason(DiveSimulation.STATION_BORE))).is_equal("feature_in_column")
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_greater(0.0)
	assert_float(sim.call_urgency(DiveSimulation.STATION_BORE)).is_greater(0.0)


func test_an_acknowledged_call_stays_silent_while_it_holds_and_sounds_again_once_it_grows_more_urgent() -> void:
	var sim := _out_of_band(1.2)
	sim.acknowledge_calls()
	DiveTestKit.run(sim, 5.0, 0.1)
	assert_bool(sim.call_sounding(DiveSimulation.STATION_REACTOR)).is_false()

	_detune(sim, 4.0)  # The Residual now far outside the Band: the Head grinds.
	sim.advance(0.1)

	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("out_of_band")
	assert_bool(sim.call_sounding(DiveSimulation.STATION_REACTOR)).is_true()


func test_an_acknowledged_call_sounds_again_when_its_reason_changes_even_to_a_less_urgent_one() -> void:
	var sim := _one_boundary(60.0)
	sim.advance(0.1)
	_detune(sim, 1.5)
	sim.advance(0.1)
	sim.acknowledge_calls()
	var acknowledged := sim.call_urgency(DiveSimulation.STATION_REACTOR)
	DiveTestKit.run_until(sim, &"boundary_approaching")
	sim.advance(0.1)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("out_of_band")
	assert_bool(sim.call_sounding(DiveSimulation.STATION_REACTOR)).is_false()

	DiveTestKit.cancel_wobble(sim)  # Back inside the Band, the Boundary still ahead.
	sim.advance(0.1)

	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("boundary_approaching")
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_less(acknowledged)
	assert_bool(sim.call_sounding(DiveSimulation.STATION_REACTOR)).is_true()


func test_a_call_that_ends_and_comes_back_sounds_again() -> void:
	var sim := _out_of_band(1.5)
	sim.acknowledge_calls()
	DiveTestKit.cancel_wobble(sim)
	sim.advance(0.1)
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_equal(0.0)

	_detune(sim, 1.5)
	sim.advance(0.1)

	assert_bool(sim.call_sounding(DiveSimulation.STATION_REACTOR)).is_true()


# --- The time rate after a warning -------------------------------------------

func test_a_raised_time_rate_is_refused_while_a_warning_sounds_and_allowed_once_it_is_acknowledged() -> void:
	var sim := _out_of_band(1.5)
	sim.set_time_rate(sim.max_time_rate())
	assert_float(sim.time_rate()).is_equal(1.0)

	sim.acknowledge_calls()
	sim.set_time_rate(sim.max_time_rate())
	sim.advance(1.0 / 60.0)

	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("out_of_band")
	assert_float(sim.time_rate()).is_equal(sim.max_time_rate())


func test_an_acknowledged_warning_that_grows_more_urgent_drops_a_raised_time_rate_again() -> void:
	var sim := _out_of_band(1.2)
	sim.acknowledge_calls()
	sim.set_time_rate(sim.max_time_rate())
	sim.advance(1.0 / 60.0)
	assert_float(sim.time_rate()).is_equal(sim.max_time_rate())

	_detune(sim, 4.0)
	sim.advance(1.0 / 60.0)

	assert_float(sim.time_rate()).is_equal(1.0)
	sim.set_time_rate(sim.max_time_rate())
	assert_float(sim.time_rate()).is_equal(1.0)


# --- The Boundary call waits for a crew that is ready ------------------------

func test_with_standby_inside_the_band_against_the_guess_the_boundary_call_begins_later_than_untuned() -> void:
	var tuned := _scanned_above_a_boundary(true)
	var untuned := _scanned_above_a_boundary(false)
	assert_float(tuned.residual(DiveSimulation.CHANNEL_STANDBY)).is_less_equal(tuned.band())
	assert_float(untuned.residual(DiveSimulation.CHANNEL_STANDBY)).is_greater(untuned.band())

	var tuned_call := _until_the_boundary_call(tuned)
	var untuned_call := _until_the_boundary_call(untuned)

	assert_bool(untuned_call.called).is_true()
	assert_bool(tuned_call.called).override_failure_message("the tuned crew's call never came before the crossing").is_true()
	assert_float(tuned_call.depth).is_greater(untuned_call.depth)

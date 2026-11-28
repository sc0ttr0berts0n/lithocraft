# The Glide (ticket #123), tested at the simulation's interface: a fast,
# straight run through scanned rock, left with the Head at idle. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

const SOFT_TO := 60.0
const HARD_TO := 400.0


## Soft rock over hard over soft: two Boundaries that echo clearly.
func _layers() -> MediumLayout:
	return MediumLayout.layered([[0.0, DiveTestKit.soft()], [SOFT_TO, DiveTestKit.hard()],
			[HARD_TO, DiveTestKit.soft()]])


## A dive at the surface with the survey's soundings of every Boundary, the
## Reactor's autopilot engaged as a crew would leave it.
func _surveyed(layout := _layers()) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.start_surveyed()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.advance(0.1)
	return sim


## Plots the whole of what the scan shows (or `metres`, held to it) and starts
## it on the next step.
func _glide(sim: DiveSimulation, metres := INF) -> void:
	sim.plot_glide(minf(metres, 100000.0))
	sim.start_glide()


## Runs until the Glide ends and returns its &"glide_ended" event.
func _glide_to_end(sim: DiveSimulation, seen: Array = [], step := 0.1) -> Dictionary:
	return DiveTestKit.run_until(sim, &"glide_ended", 600.0, seen, step)


# --- Criterion 1: faster than the Crawl ------------------------------------

func test_a_glide_covers_more_ground_than_a_crawl_in_the_same_time_and_medium() -> void:
	var layout := MediumLayout.layered([[0.0, DiveTestKit.soft()], [HARD_TO, DiveTestKit.hard()]])
	var crawl := _surveyed(layout)
	crawl.set_power(1.0)
	var glide := _surveyed(layout)
	_glide(glide)
	assert_bool(glide.gliding()).is_true()

	DiveTestKit.run(crawl, 20.0, 0.1)
	DiveTestKit.run(glide, 20.0, 0.1)

	assert_str(glide.medium().name).is_equal(crawl.medium().name)
	assert_float(glide.distance()).is_greater(crawl.distance() * 2.0)


func test_a_glide_is_slower_in_harder_rock() -> void:
	var soft := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.soft()],
			[HARD_TO, DiveTestKit.hard()]]))
	var hard := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.hard()],
			[HARD_TO, DiveTestKit.soft()]]))
	for sim in [soft, hard]:
		sim.start_surveyed()
		sim.advance(0.1)
		_glide(sim)
		DiveTestKit.run(sim, 10.0, 0.1)

	assert_float(soft.distance()).is_greater(hard.distance())


# --- Criterion 2: nothing surveyed, nothing seen ---------------------------

func test_a_glided_stretch_adds_nothing_to_the_survey() -> void:
	var sim := _surveyed()
	sim.set_power(1.0)
	DiveTestKit.run(sim, 25.0, 0.5)
	var before := sim.survey().size() + 1  # The part-stretch closes as the Glide starts.
	var value := sim.survey_value()
	_glide(sim)
	sim.advance(0.1)
	var closed := sim.survey().size()
	var at_start := sim.distance()

	_glide_to_end(sim)

	assert_float(sim.distance() - at_start).is_greater(100.0)
	assert_int(sim.survey().size()).is_equal(closed)
	assert_int(closed).is_less_equal(before)
	assert_float(sim.survey_value()).is_less_equal(value + sim.survey().back().value())


func test_a_feature_in_a_glided_stretch_is_never_seen() -> void:
	var feature := ColumnFeature.new(&"curiosity", 0.3, 50.0)
	var layout := _layers().with_features([[200.0, feature]])
	var glided := _surveyed(layout)
	_glide(glided)
	_glide_to_end(glided)
	assert_float(glided.depth()).is_greater(200.0)
	var crawled := DiveSimulation.new(layout)
	crawled.start_below(250.0)

	assert_int(crawled.found_features().size()).is_equal(1)
	assert_int(glided.found_features().size()).is_equal(0)
	# Nor afterwards: it was melted with the Column.
	glided.set_course(0.0, -90.0)
	glided.set_power(1.0)
	DiveTestKit.shift_to(glided, DiveTestKit.wobble_in(glided.medium()))
	DiveTestKit.run(glided, 900.0, 1.0)
	assert_float(glided.depth()).is_less(200.0)
	assert_int(glided.found_features().size()).is_equal(0)


func test_the_bore_station_stops_observing_when_a_glide_starts() -> void:
	var feature := ColumnFeature.new(&"curiosity", 0.3, 50.0)
	var sim := _surveyed(_layers().with_features([[5.0, feature]]))
	sim.set_power(1.0)
	for i in 200:
		sim.advance(0.1)
		if not sim.features_in_column().is_empty():
			break
	sim.set_observed_feature(sim.features_in_column()[0].id)
	assert_int(sim.observed_feature()).is_greater_equal(0)

	_glide(sim)
	sim.advance(0.1)

	assert_int(sim.observed_feature()).is_equal(-1)
	assert_array(sim.features_in_column()).is_empty()
	assert_bool(sim.column_absent(0.0)).is_true()


# --- Criterion 3: no Shift, no wear -----------------------------------------

func test_a_boundary_crossed_in_a_glide_needs_no_shift_and_wears_nothing() -> void:
	var sim := _surveyed()
	var wear := sim.head_wear()
	_glide(sim)
	var seen := []
	var out_of_band := false
	for i in 6000:
		sim.advance(0.1)
		seen.append_array(sim.take_events())
		out_of_band = out_of_band or sim.out_of_band()
		if not sim.gliding():
			break

	assert_array(DiveTestKit.types(seen)).contains([&"boundary_crossed", &"glide_ended"])
	assert_float(sim.depth()).is_greater(SOFT_TO)
	assert_bool(out_of_band).is_false()
	assert_float(sim.head_wear()).is_equal(wear)
	assert_bool(sim.plasma_lost()).is_false()
	for event in seen:
		if event.type == &"station_call":
			assert_str(event.reason).is_not_equal(&"boundary_approaching")
			assert_str(event.reason).is_not_equal(&"out_of_band")


func test_the_same_boundary_crawled_through_unshifted_wears_the_head() -> void:
	# The inversion of the rule above: the Crawl feels the Wobble change.
	var sim := DiveSimulation.new(_layers())
	sim.start_below(SOFT_TO - 2.0)
	sim.set_power(1.0)
	DiveTestKit.run_until(sim, &"boundary_crossed", 60.0)
	DiveTestKit.run(sim, 2.0, 0.1)

	assert_bool(sim.out_of_band()).is_true()
	assert_float(sim.head_wear()).is_greater(0.0)


# --- Criterion 4: pulses drowned --------------------------------------------

func test_a_pulse_sent_in_a_glide_returns_nothing() -> void:
	var sim := _surveyed()
	_glide(sim)
	DiveTestKit.run(sim, 1.0, 0.1)
	var count := sim.point_count()
	sim.take_events()

	sim.pulse()
	sim.advance(0.1)

	var sent: Array = sim.take_events().filter(
			func(e: Dictionary) -> bool: return e.type == &"pulse_sent")
	assert_int(sent.size()).is_equal(1)
	assert_bool(sent[0].drowned).is_true()
	assert_int(sim.point_count()).is_equal(count)


func test_the_same_pulse_sent_in_the_crawl_returns_echoes() -> void:
	var sim := _surveyed()
	var count := sim.point_count()

	sim.pulse()
	sim.advance(0.1)

	assert_int(sim.point_count()).is_greater(count)


func test_starting_a_glide_cuts_a_running_sweep_short() -> void:
	var sim := _surveyed()
	sim.start_sweep()
	sim.advance(0.5)
	assert_bool(sim.sweep_running()).is_true()
	sim.take_events()

	_glide(sim)
	sim.advance(0.1)

	var ended: Array = sim.take_events().filter(
			func(e: Dictionary) -> bool: return e.type == &"sweep_ended")
	assert_bool(sim.sweep_running()).is_false()
	assert_int(ended.size()).is_equal(1)
	assert_bool(ended[0].finished).is_false()


func test_a_sweep_starts_in_the_crawl_but_not_in_a_glide() -> void:
	var crawl := _surveyed()
	crawl.start_sweep()
	var glide := _surveyed()
	_glide(glide)
	DiveTestKit.run(glide, 1.0, 0.1)

	glide.start_sweep()
	glide.advance(0.1)

	assert_bool(crawl.sweep_running()).is_true()
	assert_bool(glide.sweep_running()).is_false()


func test_the_beam_pulses_by_itself_in_the_crawl_but_not_in_a_glide() -> void:
	var sim := _surveyed()
	sim.set_beam_pulsing(true)
	_glide(sim)
	var seen := []
	_glide_to_end(sim, seen)

	assert_array(DiveTestKit.types(seen)).not_contains([&"pulse_sent"])


# --- Criterion 5: no longer than the scan shows -----------------------------

func test_with_no_scan_there_is_no_glide() -> void:
	var sim := DiveSimulation.new(_layers())
	sim.advance(0.1)

	sim.plot_glide(100.0)

	assert_float(sim.glide_reach()).is_equal(0.0)
	assert_float(sim.glide_plotted()).is_equal(0.0)
	sim.start_glide()
	assert_str(sim.glide_refusal()).is_equal(&"not_plotted")
	assert_bool(sim.gliding()).is_false()


func test_a_glide_cannot_be_plotted_longer_than_the_scan_has_shown() -> void:
	var sim := _surveyed()

	sim.plot_glide(100000.0)

	assert_float(sim.glide_reach()).is_greater(0.0)
	assert_float(sim.glide_plotted()).is_equal(sim.glide_reach())
	# The scan shows the rock as far as its furthest Boundary, no further.
	assert_float(sim.glide_reach()).is_less(HARD_TO)
	assert_float(sim.glide_reach()).is_greater(SOFT_TO)
	_glide_to_end(sim)
	assert_float(sim.depth()).is_less(HARD_TO)


func test_a_better_scan_allows_a_longer_glide() -> void:
	var sim := DiveSimulation.new(_layers())
	sim.advance(0.1)
	sim.set_beam_width(DiveSimulation.BEAM_WIDE)
	DiveTestKit.quiet_scan(sim, 1)
	var rough := sim.glide_reach()
	sim.set_beam_width(DiveSimulation.BEAM_NARROW)
	DiveTestKit.quiet_scan(sim, 6)
	var better := sim.glide_reach()

	assert_float(better).is_greater(rough)


func test_the_reach_shrinks_as_the_vessel_runs_toward_the_edge_of_the_scan() -> void:
	var sim := _surveyed()
	var at_start := sim.glide_reach()
	sim.set_power(1.0)
	DiveTestKit.run(sim, 20.0, 0.5)

	assert_float(sim.glide_reach()).is_less(at_start)
	assert_float(sim.glide_reach() + sim.distance()).is_equal_approx(at_start, 0.5)


func test_a_climbing_glide_ends_short_of_the_surface() -> void:
	var far_below := 1000.0
	for depth in [50.0, 200.0]:
		var reach := Glide.reach(far_below, depth, Vector3.UP)
		assert_float(reach).is_greater(0.0)
		assert_float(reach).is_less(depth)
	# Diving, the surface does not hold it back.
	assert_float(Glide.reach(far_below, 50.0, Vector3.DOWN)).is_greater(50.0)


# --- Criterion 6: how a Glide ends ------------------------------------------

func _assert_halted_at_idle_and_lit(sim: DiveSimulation) -> void:
	assert_bool(sim.gliding()).is_false()
	assert_str(sim.glide_state()).is_equal(DiveSimulation.GLIDE_IDLE)
	assert_float(sim.speed()).is_equal(0.0)
	assert_float(sim.head_activity()).is_equal(0.0)
	assert_bool(sim.plasma_lost()).is_false()
	var at := sim.distance()
	DiveTestKit.run(sim, 30.0, 0.5)
	assert_float(sim.distance()).is_equal(at)


func test_a_glide_ends_at_its_plotted_length_halted_with_the_head_at_idle() -> void:
	var sim := _surveyed()
	_glide(sim, 150.0)
	var ended := _glide_to_end(sim)

	assert_str(ended.by).is_equal(&"plotted_length")
	assert_float(ended.glided).is_equal_approx(150.0, 0.05)
	assert_float(sim.depth()).is_equal_approx(150.0, 0.05)
	_assert_halted_at_idle_and_lit(sim)


func test_a_glide_into_harder_rock_as_it_drops_out_still_arrives_promptly() -> void:
	# The jet is held to what arrives: harder rock slows it, and it pushes on.
	var sim := _surveyed()
	_glide(sim, SOFT_TO + 20.0)
	var seconds := 0.0
	while sim.gliding() and seconds < 60.0:
		sim.advance(0.1)
		seconds += 0.1

	assert_float(sim.depth()).is_equal_approx(SOFT_TO + 20.0, 0.05)
	assert_float(seconds).is_less(6.0)


func test_a_glide_ends_on_the_crews_command_short_of_its_length() -> void:
	var sim := _surveyed()
	_glide(sim, 300.0)
	DiveTestKit.run(sim, 3.0, 0.1)
	sim.drop_out_of_glide()
	var ended := _glide_to_end(sim)

	assert_str(ended.by).is_equal(&"crew")
	assert_float(ended.glided).is_less(300.0)
	_assert_halted_at_idle_and_lit(sim)


func test_quiet_ship_drops_out_of_a_glide() -> void:
	var sim := _surveyed()
	_glide(sim, 300.0)
	DiveTestKit.run(sim, 3.0, 0.1)
	sim.set_quiet_ship(true)
	var ended := _glide_to_end(sim)

	assert_str(ended.by).is_equal(&"crew")


func test_a_long_step_at_a_raised_time_rate_never_overruns_the_plotted_length() -> void:
	var sim := _surveyed()
	_glide(sim, 150.0)
	sim.set_time_rate(sim.max_time_rate())
	var seen := []
	_glide_to_end(sim, seen, 1.0)

	assert_float(sim.depth()).is_less_equal(150.0 + 0.05)
	assert_float(sim.depth()).is_greater(150.0 - 0.05)
	# Nor passes through a surface unseen.
	assert_array(DiveTestKit.types(seen)).contains([&"boundary_crossed"])


func test_a_long_step_meets_both_surfaces_of_a_thin_layer() -> void:
	var thin := MediumLayout.layered([[0.0, DiveTestKit.soft()], [100.0, DiveTestKit.hard()],
			[102.5, DiveTestKit.soft()], [HARD_TO, DiveTestKit.hard()]])
	var sim := _surveyed(thin)
	_glide(sim, 200.0)
	sim.set_time_rate(sim.max_time_rate())
	var seen := []
	_glide_to_end(sim, seen, 1.0)

	var crossed := seen.filter(func(e: Dictionary) -> bool: return e.type == &"boundary_crossed")
	assert_int(crossed.size()).is_equal(2)


# --- Criterion 7: from idle to the Crawl -------------------------------------

func test_from_idle_the_crawl_begins_only_once_the_head_is_spun_up() -> void:
	var sim := _surveyed()
	sim.set_power(1.0)
	_glide(sim, 150.0)
	_glide_to_end(sim)
	var at := sim.distance()
	DiveTestKit.run(sim, 20.0, 0.5)
	assert_float(sim.distance()).is_equal(at)

	DiveTestKit.shift_to(sim, DiveTestKit.wobble_in(sim.medium()))
	sim.advance(0.1)
	var early := sim.speed()
	DiveTestKit.run(sim, 20.0, 0.5)

	assert_str(sim.glide_state()).is_equal(DiveSimulation.GLIDE_NONE)
	assert_float(sim.speed()).is_greater(early)
	assert_float(sim.distance()).is_greater(at)


func test_at_the_idle_no_wobble_reaches_the_plasma_and_after_it_the_rocks_does() -> void:
	var sim := _surveyed()
	_glide(sim, 150.0)
	_glide_to_end(sim)
	assert_str(sim.medium().name).is_equal(DiveTestKit.hard().name)

	assert_bool(sim.wobble_on_plasma()).is_false()
	assert_float(sim.wobble_amplitude()).is_equal(0.0)
	# STANDBY reads against the rock now round the vessel.
	var round := DiveTestKit.wobble_in(DiveTestKit.hard())
	assert_float(sim.wobble_ahead_frequency()).is_equal_approx(round.x, round.x * 0.5)

	DiveTestKit.shift_to(sim, round)
	sim.advance(0.1)

	assert_bool(sim.wobble_on_plasma()).is_true()
	assert_vector(DiveTestKit.wobble(sim)).is_equal(round)
	assert_bool(sim.out_of_band()).is_false()


func test_a_shift_left_on_the_old_rock_after_a_glide_is_out_of_the_band() -> void:
	# The inversion: the Wobble after the idle is the new rock's, not the old.
	var sim := _surveyed()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, false)
	_glide(sim, 150.0)
	_glide_to_end(sim)

	DiveTestKit.shift_to(sim, DiveTestKit.wobble_in(DiveTestKit.soft()))
	DiveTestKit.run(sim, 1.0, 0.1)

	assert_bool(sim.out_of_band()).is_true()


func test_a_glide_starts_only_straight_on_the_course() -> void:
	var sim := _surveyed()
	sim.plot_glide(100.0)
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	DiveTestKit.nudge(sim, 0.0, -15.0)
	sim.start_glide()
	assert_str(sim.glide_refusal()).is_equal(&"off_the_course")
	assert_bool(sim.gliding()).is_false()

	sim.end_override()
	assert_str(sim.glide_refusal()).is_equal(&"")


func test_steering_does_nothing_in_a_glide() -> void:
	var sim := _surveyed()
	_glide(sim, 300.0)
	sim.advance(0.1)
	var way := sim.heading()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	DiveTestKit.nudge(sim, 0.0, -15.0)
	DiveTestKit.run(sim, 5.0, 0.1)

	assert_vector(sim.heading()).is_equal_approx(way, Vector3.ONE * 1e-6)
	assert_float(sim.steering()).is_equal(0.0)


# --- Criterion 8: heat -------------------------------------------------------

func test_the_hull_is_hotter_after_a_glide_than_after_standing_still_as_long() -> void:
	var glide := _surveyed()
	var still := _surveyed()
	_glide(glide, 300.0)
	var seconds := 0.0
	while glide.gliding() and seconds < 600.0:
		glide.advance(0.1)
		still.advance(0.1)
		seconds += 0.1

	assert_float(glide.vessel_temperature()).is_greater(still.vessel_temperature())


func test_a_glide_sends_no_heat_into_the_column_and_carries_most_of_it_away() -> void:
	var sim := _surveyed()
	sim.set_heat_split(1.0)
	_glide(sim, 300.0)
	DiveTestKit.run(sim, 5.0, 0.1)

	assert_float(sim.heat_to_column()).is_equal(0.0)
	assert_float(sim.heat_carried_aft()).is_greater(sim.heat_outward())


# --- Power, calls ------------------------------------------------------------

func test_the_glide_takes_all_the_output_but_the_base_loads_and_starves_nothing() -> void:
	var sim := _surveyed()
	var crawl_output := sim.reactor_full_output()
	_glide(sim, 300.0)
	var seen := []
	for i in 50:
		sim.advance(0.1)
		seen.append_array(sim.take_events())

	assert_float(sim.reactor_output()).is_greater(crawl_output)
	assert_float(sim.drive_draw()).is_greater(crawl_output)
	assert_float(sim.power_drawn()).is_equal_approx(sim.reactor_output(), 1e-6)
	assert_float(sim.navigation_supplied()).is_equal(1.0)
	assert_float(sim.thermal_supplied()).is_equal(1.0)
	for event in seen:
		if event.type == &"station_call":
			assert_str(event.reason).is_not_equal(&"starved")


func test_the_drive_reports_the_glide_ending_and_the_reactor_the_idle() -> void:
	var sim := _surveyed()
	_glide(sim, 150.0)
	var calls := {}
	for i in 6000:
		sim.advance(0.1)
		calls[sim.call_reason(DiveSimulation.STATION_DRIVE)] = true
		if not sim.gliding():
			break
	sim.advance(0.1)

	assert_bool(calls.has(&"glide_ending")).is_true()
	assert_str(sim.call_reason(DiveSimulation.STATION_REACTOR)).is_equal(&"head_at_idle")
	assert_bool(sim.call_warns(DiveSimulation.STATION_REACTOR)).is_false()


func test_the_glide_ending_is_a_report_that_keeps_the_time_rate() -> void:
	var sim := _surveyed()
	_glide(sim, 150.0)
	sim.set_time_rate(8.0)
	_glide_to_end(sim, [], 0.1)

	assert_float(sim.time_rate()).is_equal(8.0)


# --- Tunnel, stranding --------------------------------------------------------

func test_a_glide_marks_the_stretch_it_glided() -> void:
	var sim := _surveyed()
	_glide(sim, 150.0)
	_glide_to_end(sim)

	var stretches := sim.glided_stretches()
	assert_int(stretches.size()).is_equal(1)
	assert_float(stretches[0].y - stretches[0].x).is_equal_approx(150.0, 0.05)


func test_self_destruct_drops_out_of_a_glide_and_runs_the_head_against_the_rock() -> void:
	var sim := _surveyed()
	_glide(sim, 300.0)
	DiveTestKit.run(sim, 2.0, 0.1)
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.hold_self_destruct(true)
	DiveTestKit.run(sim, sim.self_destruct_hold_length() + 0.5, 0.1)
	assert_bool(sim.self_destructing()).is_true()

	var ended := _glide_to_end(sim)
	DiveTestKit.run(sim, 1.0, 0.1)

	assert_str(ended.by).is_equal(&"crew")
	assert_str(sim.glide_state()).is_equal(DiveSimulation.GLIDE_NONE)
	assert_bool(sim.wobble_on_plasma()).is_true()
	assert_float(sim.head_activity()).is_greater(0.0)


func test_a_glide_does_not_wear_the_head_or_lose_the_plasma() -> void:
	# The plasma touches only the melt: a whole Glide leaves the Head as it was.
	var sim := _surveyed()
	var wear := sim.head_wear()
	_glide(sim)
	_glide_to_end(sim)

	assert_float(sim.head_wear()).is_equal(wear)
	assert_bool(sim.plasma_lost()).is_false()

# Debug commands, tested at the simulation's interface: the developer's
# shortcuts for testing a dive by hand (the numpad debug menu). Not crew
# controls: each reaches the state it names at once, whatever the Stations.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## A dive straight down at full power through the first dive's layers.
func _under_way(seconds := 30.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	sim.set_power(1.0)
	DiveTestKit.run(sim, seconds)
	sim.take_events()
	return sim


func test_hull_wear_raised_and_lowered() -> void:
	var sim := _under_way()
	var whole := sim.hull_integrity()

	sim.debug_wear_hull(0.3)
	var worn := sim.hull_integrity()
	sim.debug_wear_hull(-0.2)
	var mended := sim.hull_integrity()

	assert_float(worn).is_less(whole)
	assert_float(mended).is_greater(worn)
	assert_float(mended).is_less(whole)


func test_a_hull_worn_through_fails_on_the_next_step() -> void:
	var sim := _under_way()

	sim.debug_wear_hull(2.0)
	sim.advance(0.1)

	assert_bool(sim.dead()).is_true()
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"hull_failed"])


func test_the_hull_brought_to_the_brink_still_holds_but_fails_soonest() -> void:
	var brink := _under_way()
	var whole := _under_way()
	var worn := _under_way()
	worn.debug_wear_hull(0.5)

	brink.debug_hull_to_brink()
	brink.advance(0.1)

	assert_bool(brink.dead()).is_false()
	assert_float(brink.hull_integrity()).is_greater(0.0)
	assert_float(brink.hull_integrity()).is_less(worn.hull_integrity())
	assert_float(brink.stranding_clock()).is_less(worn.stranding_clock())
	assert_float(worn.stranding_clock()).is_less(whole.stranding_clock())


func test_head_wear_raised_and_lowered_narrows_and_widens_the_band() -> void:
	var sim := _under_way()
	sim.set_power(0.0)
	DiveTestKit.run(sim, 600.0)  # At rest, so only the wear moves the Band.
	var fresh_band := sim.band()

	sim.debug_wear_head(0.6)
	sim.advance(0.1)
	var worn := sim.head_wear()
	var worn_band := sim.band()
	sim.debug_wear_head(-0.4)
	sim.advance(0.1)

	assert_float(worn).is_greater(0.0)
	assert_float(worn_band).is_less(fresh_band)
	assert_float(sim.head_wear()).is_less(worn)
	assert_float(sim.head_wear()).is_greater(0.0)
	assert_float(sim.band()).is_greater(worn_band)
	assert_bool(sim.plasma_lost()).is_false()


func test_strand_now_seals_the_tunnel_and_loses_the_plasma_with_a_rescue_to_wait_for() -> void:
	var sim := _under_way()
	assert_bool(sim.tunnel_sealed()).is_false()

	sim.debug_strand()

	assert_bool(sim.stranded()).is_true()
	assert_bool(sim.tunnel_sealed()).is_true()
	assert_bool(sim.on_emergency_store()).is_true()
	assert_float(sim.rescue_time()).is_greater(0.0)
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"stranded"])
	# Stranded, the dive waits on the rescue rather than ending at once.
	sim.advance(1.0)
	assert_bool(sim.stranded()).is_true()


func test_strand_now_does_nothing_before_the_tail_leaves_the_surface() -> void:
	var sim := DiveSimulation.new(MediumLayout.first_dive())

	sim.debug_strand()
	sim.advance(0.1)

	assert_bool(sim.stranded()).is_false()
	assert_bool(sim.plasma_lost()).is_false()


func test_losing_the_plasma_with_the_tunnel_open_brings_the_crew_home() -> void:
	var sim := _under_way()

	sim.debug_lose_plasma()

	assert_bool(sim.surfaced()).is_true()
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"plasma_lost", &"brought_home"])


func test_losing_the_plasma_sealed_in_strands() -> void:
	var sealed := _sealed_in()

	sealed.debug_lose_plasma()

	assert_bool(sealed.stranded()).is_true()


func test_refilling_the_emergency_store_fills_it() -> void:
	var sim := _under_way()
	sim.debug_strand()
	sim.set_heat_split(1.0)  # The pumps cool the hull on the store.
	DiveTestKit.run(sim, 60.0)
	var spent := sim.emergency_store()
	assert_float(spent).is_less(sim.emergency_store_capacity())

	sim.debug_refill_store()

	assert_float(sim.emergency_store()).is_equal(sim.emergency_store_capacity())


func test_surface_now_ends_the_dive_at_the_surface_and_pays_for_it() -> void:
	var sim := _under_way()
	assert_float(sim.depth()).is_greater(0.0)

	sim.debug_surface()

	assert_bool(sim.surfaced()).is_true()
	assert_float(sim.depth()).is_equal(0.0)
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"surfaced", &"paid"])


func test_surface_now_while_stranded_is_the_rescue_arriving_and_billed() -> void:
	var sim := _under_way()
	sim.debug_strand()
	sim.take_events()

	sim.debug_surface()

	assert_bool(sim.surfaced()).is_true()
	assert_bool(sim.stranded()).is_false()
	var events := sim.take_events()
	assert_array(DiveTestKit.types(events)).contains([&"rescued", &"paid"])
	assert_array(DiveTestKit.types(events)).not_contains([&"surfaced"])
	var paid: Dictionary = events.filter(func(e: Dictionary) -> bool: return e.type == &"paid")[0]
	assert_float(paid.rescue).is_greater(0.0)


func test_a_debug_command_that_acts_gives_no_reason_and_one_that_cannot_says_why() -> void:
	var sim := _under_way()
	var at_surface := DiveSimulation.new(MediumLayout.first_dive())
	var level := _under_way()
	level.set_autopilot(DiveSimulation.STATION_REACTOR, true)  # It crosses a Boundary on the way round.
	level.set_attended(DiveSimulation.STATION_DRIVE, true)
	level.set_power(0.3)
	level.set_course(0.0, 0.0)
	for i in 3000:
		if absf(level.pitch()) < 0.5 or level.dead():
			break
		level.advance(1.0)
	assert_float(absf(level.pitch())).is_less(0.5)

	assert_str(String(sim.debug_wear_hull(0.1))).is_empty()
	assert_str(String(sim.debug_next_boundary())).is_empty()
	assert_str(String(at_surface.debug_strand())).is_not_empty()
	assert_str(String(level.debug_next_boundary())).is_not_empty()
	assert_str(String(sim.debug_strand())).is_empty()
	assert_str(String(sim.debug_strand())).is_not_empty()  # Already stranded.
	assert_str(String(sim.debug_lose_plasma())).is_not_empty()  # Already lost.
	assert_str(String(sim.debug_detune())).is_not_empty()  # No plasma to detune.
	assert_str(String(sim.debug_self_destruct())).is_empty()
	assert_str(String(sim.debug_self_destruct())).is_not_empty()  # Already running.


func test_every_debug_command_says_why_once_the_dive_is_over() -> void:
	var sim := _under_way()
	sim.debug_surface()
	var reasons := [sim.debug_wear_hull(0.1), sim.debug_hull_to_brink(), sim.debug_wear_head(0.1),
			sim.debug_lose_plasma(), sim.debug_strand(), sim.debug_refill_store(), sim.debug_surface(),
			sim.debug_skip(10.0), sim.debug_self_destruct(), sim.debug_detune(),
			sim.debug_next_boundary()]

	for reason in reasons:
		assert_str(String(reason)).is_not_empty()
		assert_str(String(reason)).is_equal(String(reasons[0]))


func test_skipping_time_runs_the_dive_on_whatever_calls() -> void:
	# Down through Boundaries, where the Reactor calls for a Shift: a call
	# returns a raised time rate to normal, but does not cut a skip short.
	var skipped := _under_way()
	var waited := _under_way()
	var from := skipped.distance()

	skipped.debug_skip(120.0)
	DiveTestKit.run(waited, 120.0)

	var travelled := waited.distance() - from
	assert_float(travelled).is_greater(0.0)
	assert_float(skipped.distance() - from).is_equal_approx(travelled, travelled * 0.02)


func test_skipping_time_stranded_brings_the_rescue_nearer_by_that_time() -> void:
	var sim := _under_way()
	sim.debug_strand()
	var before := sim.rescue_time()

	sim.debug_skip(60.0)

	assert_float(before - sim.rescue_time()).is_equal_approx(60.0, 0.5)


func test_self_destruct_now_starts_it_without_the_hold() -> void:
	var sim := _under_way()

	sim.debug_self_destruct()

	assert_bool(sim.self_destructing()).is_true()
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"self_destruct_started"])
	# It runs as a held one does: the crew cancel it at Thermal.
	sim.cancel_self_destruct()
	assert_bool(sim.self_destructing()).is_false()


func test_detuning_active_now_puts_the_residual_outside_the_band() -> void:
	var sim := _under_way()
	sim.set_attended(DiveSimulation.STATION_REACTOR, true)
	DiveTestKit.cancel_wobble(sim)
	sim.advance(0.1)
	assert_bool(sim.out_of_band()).is_false()

	sim.debug_detune()

	assert_bool(sim.out_of_band()).is_true()
	# In frequency: the Residual beats.
	assert_float(sim.residual_beat(DiveSimulation.CHANNEL_ACTIVE)).is_greater(0.0)
	sim.advance(0.1)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("out_of_band")


func test_jumping_to_the_next_boundary_crosses_it_and_stops_short_of_the_one_after() -> void:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	var boundaries := MediumLayout.first_dive().boundary_depths()
	var first := sim.medium().name

	sim.debug_next_boundary()

	assert_float(sim.depth()).is_greater(boundaries[0])
	assert_float(sim.depth()).is_less(boundaries[1])
	assert_str(String(sim.medium().name)).is_not_equal(String(first))
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"boundary_crossed"])
	# The Head cut its way there: the Column passed is recorded, and the
	# Boundary lies in the Bore just behind the Head.
	assert_array(sim.survey()).is_not_empty()
	assert_str(String(sim.column_at(0.1).name)).is_equal(String(sim.medium().name))
	assert_str(String(sim.column_at(sim.vessel_length()).name)).is_equal(String(first))

	sim.debug_next_boundary()

	assert_float(sim.depth()).is_greater(boundaries[1])


func test_jumping_climbing_crosses_the_boundary_above() -> void:
	var soft := DiveTestKit.rock(0.5)
	var layout := MediumLayout.layered([[0.0, soft], [100.0, DiveTestKit.basalt()], [200.0, soft]])
	var boundaries := layout.boundary_depths()
	var sim := DiveSimulation.new(layout)
	sim.debug_next_boundary()
	sim.debug_next_boundary()
	# Turn gently up, cool enough that the hull bears it.
	sim.set_power(0.3)
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_course(0.0, -90.0)
	for i in 2000:
		if sim.pitch() < -5.0 or sim.dead():
			break
		sim.advance(1.0)
	assert_bool(sim.dead()).is_false()
	assert_float(sim.pitch()).is_less(0.0)
	assert_float(sim.depth()).is_greater(boundaries[1])
	var from := sim.depth()

	sim.debug_next_boundary()

	assert_float(sim.depth()).is_less(from)
	assert_float(sim.depth()).is_less(boundaries[1])
	assert_float(sim.depth()).is_greater(boundaries[0])


func test_debug_commands_are_not_station_commands_so_self_destruct_does_not_lock_them() -> void:
	var sim := _under_way()
	sim.debug_self_destruct()
	var before := sim.hull_integrity()

	sim.debug_wear_hull(0.2)

	assert_float(sim.hull_integrity()).is_less(before)


func test_debug_commands_do_nothing_once_the_dive_is_over() -> void:
	var sim := _under_way()
	sim.debug_wear_hull(2.0)
	sim.advance(0.1)
	assert_bool(sim.dead()).is_true()
	sim.take_events()

	sim.debug_wear_hull(-1.0)
	sim.debug_surface()
	sim.debug_skip(60.0)

	assert_bool(sim.dead()).is_true()
	assert_bool(sim.surfaced()).is_false()
	assert_float(sim.hull_integrity()).is_equal(0.0)
	assert_array(sim.take_events()).is_empty()


## A dive at full power until the tunnel behind is sealed, the Reactor and
## Thermal left to their autopilots.
func _sealed_in() -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	sim.set_power(1.0)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	for i in 3000:
		if sim.tunnel_sealed():
			break
		sim.advance(1.0)
	assert_bool(sim.tunnel_sealed()).is_true()
	sim.take_events()
	return sim
# The Glide's tunnel (ticket #125), tested at the simulation's interface: open
# and rough in porous rock, so the light up it is scattered and the link
# slower; sealed in dense rock as the Crawl's is. Assert relationships, never
# tuned constants (ADR 0001).
extends GdUnitTestSuite

const POROUS_TO := 60.0
const DENSE_TO := 400.0


## Test values only: hard rock with no pore space for the melt to line.
func _dense() -> Medium:
	return Medium.new(&"dense", 4.0, 6.0, 0.0, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


## Soft rock over hard over soft, all porous: the tunnel stays open.
func _porous_layers() -> MediumLayout:
	return MediumLayout.layered([[0.0, DiveTestKit.soft()], [POROUS_TO, DiveTestKit.hard()],
			[DENSE_TO, DiveTestKit.soft()]])


## Porous soft rock over dense rock over soft: the tunnel seals once the Tail
## leaves the dense rock's top.
func _sealing_layers() -> MediumLayout:
	return MediumLayout.layered([[0.0, DiveTestKit.soft()], [POROUS_TO, _dense()],
			[DENSE_TO, DiveTestKit.soft()]])


## A dive at the surface with the survey's soundings, the Reactor's autopilot
## engaged as a crew would leave it.
func _surveyed(layout := _porous_layers()) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.start_surveyed()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.advance(0.1)
	return sim


## Glides `metres` and runs until it ends at idle; returns every event seen.
func _glide(sim: DiveSimulation, metres: float, step := 0.1) -> Array:
	sim.plot_glide(metres)
	sim.start_glide()
	var seen := []
	DiveTestKit.run_until(sim, &"glide_ended", 600.0, seen, step)
	return seen


## Spins the Head up out of the idle and crawls at full power until the Head
## is `metres` further on.
func _crawl_on(sim: DiveSimulation, metres: float) -> void:
	if sim.glide_state() == DiveSimulation.GLIDE_IDLE:
		DiveTestKit.shift_to(sim, DiveTestKit.wobble_in(sim.medium()))
	sim.set_power(1.0)
	var to := sim.distance() + metres
	for i in 20000:
		if sim.distance() >= to:
			return
		sim.advance(0.1)


## Crawls on until the Tail has left all the tunnel the Head has cut so far.
func _tail_past_the_head(sim: DiveSimulation) -> void:
	_crawl_on(sim, sim.vessel_length() + 1.0)


# --- Criterion 1: slower after a glided stretch -----------------------------

func test_the_open_link_is_slower_after_a_glided_stretch_than_after_the_same_stretch_crawled() -> void:
	var glided := _surveyed()
	_glide(glided, 100.0)
	_tail_past_the_head(glided)
	var crawled := _surveyed()
	_crawl_on(crawled, glided.distance())

	for sim: DiveSimulation in [glided, crawled]:
		assert_bool(sim.tunnel_sealed()).is_false()
		assert_bool(sim.uploading()).is_true()
	assert_float(glided.link_rate()).is_greater(0.0)
	assert_float(glided.link_rate()).is_less(crawled.link_rate())


func test_glided_data_waiting_is_paid_for_more_slowly() -> void:
	# The same oldest survey waiting aboard (the first 30 m, crawled in both),
	# sent oldest first up a glass tunnel and up one with a glided stretch in
	# it: after the same time the rough one has paid less.
	var glided := _surveyed()
	var crawled := _surveyed()
	for sim: DiveSimulation in [glided, crawled]:
		sim.set_uploading(false)
		_crawl_on(sim, 30.0)
	_glide(glided, 100.0)
	_tail_past_the_head(glided)
	_crawl_on(crawled, glided.distance() - crawled.distance())
	for sim: DiveSimulation in [glided, crawled]:
		sim.set_power(0.0)
		assert_float(sim.paid()).is_equal(0.0)
		sim.set_uploading(true)
		DiveTestKit.run(sim, 25.0, 0.5)

	assert_float(glided.paid()).is_greater(0.0)
	assert_float(crawled.paid()).is_greater(glided.paid())


# --- Criterion 2: more glided stretches, slower still -----------------------

func test_two_glided_stretches_behind_slow_the_link_more_than_one() -> void:
	# The second shorter than the first, so it is the two together that slow
	# it, not the second alone.
	var sim := _surveyed()
	_glide(sim, 100.0)
	_crawl_on(sim, 2.0 * sim.vessel_length())
	var after_one := sim.link_rate()
	_glide(sim, 50.0)
	_tail_past_the_head(sim)

	assert_int(sim.glided_stretches().size()).is_equal(2)
	assert_bool(sim.tunnel_sealed()).is_false()
	assert_float(sim.link_rate()).is_less(after_one)


func test_a_longer_glided_stretch_slows_the_link_more() -> void:
	var short := _surveyed()
	_glide(short, 50.0)
	_tail_past_the_head(short)
	var long := _surveyed()
	_glide(long, 200.0)
	_tail_past_the_head(long)

	assert_float(long.rough_tunnel_metres()).is_greater(short.rough_tunnel_metres())
	assert_float(long.link_rate()).is_less(short.link_rate())


func test_two_glided_stretches_slow_it_more_than_one_as_long_as_both() -> void:
	# Light is lost where each rough run begins, as well as along it.
	var whole := _surveyed()
	_glide(whole, 120.0)
	_tail_past_the_head(whole)
	var halves := _surveyed()
	_glide(halves, 60.0)
	_crawl_on(halves, 2.0 * halves.vessel_length())
	_glide(halves, 60.0)
	_tail_past_the_head(halves)

	assert_int(halves.rough_tunnel_runs()).is_greater(whole.rough_tunnel_runs())
	assert_float(halves.rough_tunnel_metres()).is_less_equal(whole.rough_tunnel_metres() + 0.5)
	assert_float(halves.link_rate()).is_less(whole.link_rate())


func test_the_tunnel_walls_read_rough_where_glided_and_glass_where_crawled() -> void:
	var sim := _surveyed()
	_glide(sim, 100.0)
	_tail_past_the_head(sim)
	var glided := sim.glided_stretches()[0]

	var walls := sim.tunnel_walls()
	assert_int(walls.size()).is_equal(sim.tunnel_wall_count())
	assert_str(String(walls[0].wall)).is_equal(String(DiveSimulation.TUNNEL_ROUGH))
	assert_float(walls[0].to).is_equal_approx(glided.y, 0.05)
	assert_str(String(walls.back().wall)).is_equal(String(DiveSimulation.TUNNEL_GLASS))
	assert_float(walls.back().to).is_equal_approx(sim.distance() - sim.vessel_length(), 0.01)


# --- Criterion 3: sealed in dense rock ---------------------------------------

func test_a_glide_into_dense_rock_seals_the_tunnel_with_the_crawls_call_and_event() -> void:
	var sim := _surveyed(_sealing_layers())
	var light := sim.link_capacity()
	var seen := _glide(sim, 150.0)

	var calls := seen.filter(func(e: Dictionary) -> bool: return e.type == &"station_call" and e.reason == &"tunnel_about_to_seal")
	var types := DiveTestKit.types(seen)
	assert_int(calls.size()).is_greater(0)
	assert_int(types.count(&"tunnel_sealed")).is_equal(1)
	assert_int(seen.find(calls[0])).is_less(types.find(&"tunnel_sealed"))
	assert_bool(sim.tunnel_sealed()).is_true()
	assert_float(sim.link_light_share()).is_equal(0.0)
	assert_float(sim.link_capacity()).is_less(light)
	assert_str(String(sim.tunnel_walls().back().wall)).is_equal(String(DiveSimulation.TUNNEL_SEALED))


func test_a_glide_that_reaches_the_seal_within_one_long_step_still_calls_it() -> void:
	var sim := _surveyed(_sealing_layers())
	sim.plot_glide(150.0)
	sim.start_glide()
	var seen := []
	# In short steps to just short of the dense rock, at the jet's full thrust;
	# then one long step at the top time rate carries the Tail into it.
	for i in 10000:
		if sim.distance() >= POROUS_TO - 10.0:
			break
		sim.advance(0.01)
	assert_bool(sim.gliding()).is_true()
	sim.set_time_rate(sim.max_time_rate())
	DiveTestKit.run_until(sim, &"tunnel_sealed", 60.0, seen, 1.0)

	var calls := seen.filter(func(e: Dictionary) -> bool: return e.type == &"station_call" and e.reason == &"tunnel_about_to_seal")
	assert_bool(sim.tunnel_sealed()).is_true()
	assert_int(calls.size()).is_equal(1)
	assert_float(sim.time_rate()).is_equal(1.0)  # A warning: the time rate falls back.


func test_the_same_dense_rock_crawled_seals_with_the_same_call_and_event() -> void:
	var sim := _surveyed(_sealing_layers())
	var seen := []
	sim.set_power(1.0)
	DiveTestKit.run_until(sim, &"tunnel_sealed", 2000.0, seen, 0.5)

	var calls := seen.filter(func(e: Dictionary) -> bool: return e.type == &"station_call" and e.reason == &"tunnel_about_to_seal")
	assert_int(calls.size()).is_greater(0)
	assert_bool(sim.tunnel_sealed()).is_true()


# --- Criterion 4: rescue and stranding read it by the same rule ---------------

func test_a_rescue_after_a_glide_takes_as_long_as_after_the_same_path_crawled() -> void:
	var glided := _surveyed(_sealing_layers())
	_glide(glided, 150.0)
	var crawled := _surveyed(_sealing_layers())
	_crawl_on(crawled, glided.distance())

	assert_bool(glided.tunnel_sealed()).is_true()
	assert_float(glided.rescue_time()).is_equal_approx(crawled.rescue_time(), crawled.rescue_time() * 0.01)


func test_a_rescue_after_a_glide_through_porous_rock_runs_the_open_tunnel() -> void:
	var porous := _surveyed()
	_glide(porous, 150.0)
	var sealed := _surveyed(_sealing_layers())
	_glide(sealed, 150.0)

	assert_float(porous.rescue_time()).is_less(sealed.rescue_time())


func test_the_plasma_lost_after_a_glide_through_porous_rock_brings_the_crew_home() -> void:
	var sim := _surveyed()
	_glide(sim, 100.0)
	_crawl_on(sim, 2.0)
	DiveTestKit.lose_plasma(sim)

	assert_str(String(sim.outcome().ending)).is_equal("brought_home")


func test_the_plasma_lost_after_a_glide_into_dense_rock_strands_the_crew() -> void:
	var sim := _surveyed(_sealing_layers())
	_glide(sim, 150.0)
	_crawl_on(sim, 2.0)
	DiveTestKit.lose_plasma(sim)

	assert_bool(sim.stranded()).is_true()

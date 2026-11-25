# The tunnel behind, the link to the surface, and payment for survey data,
# tested at the simulation's interface. Assert relationships, never tuned
# constants (ADR 0001).
extends GdUnitTestSuite


## Test values only. Two Media alike in every way that moves the vessel, one
## full of pore space for the melt to line, one with none at all.
func _pumice() -> Medium:
	return Medium.new(&"pumice", 1.0, 0.5, 0.9, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _hornfels() -> Medium:
	return Medium.new(&"hornfels", 1.0, 0.5, 0.0, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


## Advances in one-second steps until the condition holds or time runs out.
## Returns the simulated seconds taken, or -1 if it never held.
func _advance_until(sim: DiveSimulation, condition: Callable, limit: float) -> float:
	var t := 0.0
	while t < limit:
		if condition.call():
			return t
		sim.advance(1.0)
		t += 1.0
	return t if condition.call() else -1.0


func test_the_tunnel_seals_once_the_tail_leaves_dense_medium_and_the_link_slows() -> void:
	var boundary := 100.0
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _pumice()], [boundary, _hornfels()]]))
	sim.set_power(0.5)

	sim.advance(1.0)
	assert_bool(sim.tunnel_sealed()).is_false()
	var open_rate := sim.link_rate()

	# The Head has crossed into dense Medium, but the Tail is still leaving
	# porous Medium behind it, so the tunnel is still open.
	_advance_until(sim, func() -> bool: return sim.distance() > boundary, 10000.0)
	assert_bool(sim.tunnel_sealed()).is_false()
	assert_float(sim.link_rate()).is_equal_approx(open_rate, 0.0001)

	var sealed_after := _advance_until(sim, sim.tunnel_sealed, 10000.0)
	assert_float(sealed_after).is_greater(0.0)
	assert_float(sim.link_rate()).is_less(open_rate)


func test_sealing_raises_one_tunnel_sealed_event() -> void:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _pumice()], [50.0, _hornfels()]]))
	sim.set_power(0.5)
	_advance_until(sim, func() -> bool: return sim.distance() > 45.0, 10000.0)
	assert_array(sim.take_events()).is_empty()

	_advance_until(sim, sim.tunnel_sealed, 10000.0)
	for i in 200:
		sim.advance(1.0)

	var events := sim.take_events()
	assert_int(events.size()).is_equal(1)
	assert_str(events[0].type).is_equal(&"tunnel_sealed")
	assert_array(sim.take_events()).is_empty()


func test_data_sent_up_the_fast_link_is_paid_for_sooner_than_up_the_slow_link() -> void:
	# The same dive through the same rock, but for porosity: one tunnel stays
	# open behind, the other is filled in as soon as the Tail leaves the surface.
	var open := DiveSimulation.new(MediumLayout.uniform(_pumice()))
	var sealed := DiveSimulation.new(MediumLayout.uniform(_hornfels()))
	for sim: DiveSimulation in [open, sealed]:
		sim.set_power(0.5)
		for i in 300:
			sim.advance(1.0)

	assert_bool(open.tunnel_sealed()).is_false()
	assert_bool(sealed.tunnel_sealed()).is_true()
	assert_int(open.survey().size()).is_equal(sealed.survey().size())
	assert_float(open.paid()).is_greater(sealed.paid())


func _total_value(stretches: Array[SurveyStretch]) -> float:
	var total := 0.0
	for stretch in stretches:
		total += stretch.value()
	return total


func test_survey_data_that_has_not_reached_the_surface_is_not_paid_for() -> void:
	# Dense rock that carries no sound: once sealed in, nothing goes up at all.
	var deaf := Medium.new(&"deaf", 1.0, 0.5, 0.0, 300.0, 1.0, {&"quartz": 1.0}, 0.0)
	var sim := DiveSimulation.new(MediumLayout.uniform(deaf))
	sim.set_power(0.5)
	for i in 300:
		sim.advance(1.0)
	sim.set_power(0.0)
	var paid_when_stopped := sim.paid()

	sim.advance(100000.0)

	assert_bool(sim.tunnel_sealed()).is_true()
	assert_float(sim.paid()).is_equal_approx(paid_when_stopped, 0.0001)
	assert_int(sim.uploaded_survey().size()).is_less(sim.survey().size())
	assert_float(sim.paid()).is_less(_total_value(sim.survey()))
	assert_float(sim.paid()).is_equal_approx(_total_value(sim.uploaded_survey()), 0.0001)


func test_once_the_link_has_sent_it_all_the_whole_survey_is_paid_for() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_pumice()))
	sim.set_power(0.5)
	for i in 300:
		sim.advance(1.0)
	sim.set_power(0.0)
	sim.advance(100000.0)

	assert_int(sim.uploaded_survey().size()).is_equal(sim.survey().size())
	assert_float(_total_value(sim.survey())).is_greater(0.0)
	assert_float(sim.paid()).is_equal_approx(_total_value(sim.survey()), 0.0001)

# The Reactor and the power budget, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: a Medium strong enough that the grip waves never slip.
func _rock() -> Medium:
	return Medium.new(&"rock", 2.0, 2.0, 0.05, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _sim(power: float, to_column := 0.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(_rock()))
	sim.set_power(power)
	sim.set_heat_split(to_column)
	return sim


func _run(sim: DiveSimulation, seconds: float, step := 0.5) -> DiveSimulation:
	for i in int(seconds / step):
		sim.advance(step)
	return sim


func test_power_drawn_never_exceeds_what_the_reactor_supplies() -> void:
	for quiet in [false, true]:
		for power in [0.0, 0.5, 1.0]:
			for to_column in [0.0, 0.5, 1.0]:
				var sim := _sim(power, to_column)
				sim.set_quiet_ship(quiet)
				for i in 40:
					sim.advance(0.5)
					var drawn: float = sim.drive_draw() + sim.thermal_draw() + sim.navigation_draw()
					assert_float(drawn).is_equal_approx(sim.power_drawn(), 1e-9)
					assert_float(sim.power_drawn()).is_less_equal(sim.reactor_output() + 1e-9)

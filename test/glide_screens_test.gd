# The Glide on the Stations' screens (ticket #123): Navigation's and the
# Drive's show the plotted Glide, the range left and the Glide's state; the
# Reactor says no Wobble reaches the plasma and, after, that the Head idles;
# the Bore Station that there is no Column to read. Staged as a screenshot's
# tile is, on the First dive, which starts surveyed.
extends GdUnitTestSuite


func _staged(look: String, seconds: float, commands: Array) -> Node:
	var args := ["--look", look, "--time", str(seconds), "--out", "unused.png"]
	for command: String in commands:
		args.append_array(["--do", command])
	var habitat := DiveTestKit.staged_shot(self, args)
	await DiveTestKit.laid_out(self)
	return habitat


func _written(habitat: Node, station_name: String) -> String:
	return "\n".join(DiveTestKit.station(habitat, station_name).screen().texts())


func test_a_plotted_glide_shows_on_navigation_and_the_drive() -> void:
	var habitat := await _staged("Drive", 3.0, ["1 plot_glide 300"])
	var sim: DiveSimulation = habitat.simulation()
	assert_float(sim.glide_plotted()).is_equal(300.0)

	assert_str(_written(habitat, "Navigation")).contains("Glide 300 m plotted")
	assert_str(_written(habitat, "Drive")).contains("Glide 300 m plotted")


func test_a_running_glide_shows_its_range_left_and_state() -> void:
	var habitat := await _staged("Drive", 3.0, ["1 plot_glide 300", "1 start_glide"])
	var sim: DiveSimulation = habitat.simulation()
	assert_bool(sim.gliding()).is_true()
	var left := "%d m left" % roundi(sim.glide_range_left())

	assert_str(_written(habitat, "Navigation")).contains("GLIDING  " + left)
	assert_str(_written(habitat, "Drive")).contains("GLIDE  " + left)
	assert_str(_written(habitat, "Reactor")).contains("GLIDE: no Wobble")
	assert_str(_written(habitat, "Reactor").to_lower()).not_contains("nan")
	assert_str(_written(habitat, "Bore Station")).contains("No Column in the Bore")


func test_after_a_glide_the_screens_say_the_head_is_at_idle() -> void:
	var habitat := await _staged("Drive", 12.0, ["1 plot_glide 150", "1 start_glide"])
	var sim: DiveSimulation = habitat.simulation()
	assert_str(sim.glide_state()).is_equal(DiveSimulation.GLIDE_IDLE)

	assert_str(_written(habitat, "Drive")).contains("HEAD AT IDLE")
	assert_str(_written(habitat, "Reactor")).contains("AT IDLE")


func test_after_a_glide_the_bore_station_says_why_the_link_is_slower() -> void:
	var habitat := await _staged("Bore Station", 12.0, ["1 plot_glide 150", "1 start_glide"])
	var sim: DiveSimulation = habitat.simulation()
	assert_bool(sim.tunnel_sealed()).is_false()
	var panel: TunnelPanel = habitat.find_children("*", "TunnelPanel", true, false)[0]

	assert_str(panel.link_line()).contains("1 rough stretch")
	assert_str(panel.link_line()).contains("%d%%" % roundi(100.0 * sim.link_light_share()))
	assert_str(panel.link_line()).contains("%.2f m/s" % sim.link_rate())

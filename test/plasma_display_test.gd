# The Reactor's instrument (PlasmaDisplay): two lanes, ACTIVE and STANDBY,
# each its Wobble and Counter-wave beside its Residual against the Band; under
# them the Boundary countdown, the Band and the Head's wear. Plain view logic
# over the simulation: what is drawn is what the simulation grades.
extends GdUnitTestSuite

const ACTIVE := DiveSimulation.CHANNEL_ACTIVE
const STANDBY := DiveSimulation.CHANNEL_STANDBY


## Under way in one rock, the Wobble cancelled.
func _steady() -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))
	sim.set_power(0.5)
	sim.advance(0.1)
	return sim


## Under way in soft rock above a Boundary into harder rock.
func _above_a_boundary() -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.basalt()], [100.0, DiveTestKit.rock(4.0)]]))
	sim.set_power(0.5)
	sim.advance(0.1)
	return sim


## The instrument in the tree at the size a Station's screen gives it, its
## writing brought up to the simulation.
func _display(sim: DiveSimulation) -> PlasmaDisplay:
	var display: PlasmaDisplay = auto_free(PlasmaDisplay.new())
	display.sim = sim
	display.size = Vector2(800.0, 270.0)
	add_child(display)
	display.refresh()
	return display


## How far the furthest point of a channel's drawn Residual lies from the
## middle of its plot, in pixels.
func _reach_px(display: PlasmaDisplay, channel: StringName) -> float:
	var mid := display.residual_plot(channel).get_center().y
	var reach := 0.0
	for point in display.residual_points(channel):
		reach = maxf(reach, absf(point.y - mid))
	return reach


## Half the drawn Band's height in a channel's plot, in pixels.
func _band_px(display: PlasmaDisplay, channel: StringName) -> float:
	var edges := display.band_edges(channel)
	return (edges.y - edges.x) / 2.0


# --- The Band on screen is the Band the simulation wears the Head by ---------

func test_the_drawn_band_is_the_simulations_band_at_the_residuals_own_scale() -> void:
	var sim := _steady()
	var display := _display(sim)

	for channel: StringName in [ACTIVE, STANDBY]:
		var plot := display.residual_plot(channel)
		var edges := display.band_edges(channel)
		# Centred on the line a flat Residual lies along.
		assert_float((edges.x + edges.y) / 2.0).is_equal_approx(plot.get_center().y, 0.01)
		# Its half height is band() in the plot's pixels per unit of Residual.
		var px_per_unit := plot.size.y / 2.0 / PlasmaDisplay.RESIDUAL_SCALE
		assert_float(_band_px(display, channel) / px_per_unit).is_equal_approx(sim.band(), 0.0001)
		# And the Residual is drawn at that same scale.
		assert_float(PlasmaDisplay.value_y(plot, sim.band(), PlasmaDisplay.RESIDUAL_SCALE)) \
				.is_equal_approx(edges.x, 0.01)
		assert_float(PlasmaDisplay.value_y(plot, -sim.band(), PlasmaDisplay.RESIDUAL_SCALE)) \
				.is_equal_approx(edges.y, 0.01)


func test_a_bigger_value_is_drawn_higher_and_one_off_the_scale_is_pinned_to_the_plots_edge() -> void:
	var plot := Rect2(10.0, 20.0, 200.0, 80.0)

	assert_float(PlasmaDisplay.value_y(plot, 0.0, 0.5)).is_equal_approx(60.0, 0.001)
	assert_float(PlasmaDisplay.value_y(plot, 0.25, 0.5)).is_equal_approx(40.0, 0.001)
	assert_float(PlasmaDisplay.value_y(plot, 0.5, 0.5)).is_equal_approx(20.0, 0.001)
	assert_float(PlasmaDisplay.value_y(plot, 3.0, 0.5)).is_equal_approx(20.0, 0.001)
	assert_float(PlasmaDisplay.value_y(plot, -3.0, 0.5)).is_equal_approx(100.0, 0.001)


func test_the_residual_is_drawn_inside_the_drawn_band_exactly_while_the_simulation_holds_it_inside() -> void:
	var sim := _steady()
	var display := _display(sim)
	# An amplitude a little off: a Residual the Head bears.
	DiveTestKit.tune(sim, ACTIVE, DiveTestKit.wobble(sim) + Vector2(0.0, 0.5 * sim.band()))
	sim.advance(0.1)
	assert_bool(sim.out_of_band()).is_false()
	assert_float(_reach_px(display, ACTIVE)).is_less_equal(_band_px(display, ACTIVE))

	# Further off: the Head wears, and the line is seen to leave the Band.
	DiveTestKit.tune(sim, ACTIVE, DiveTestKit.wobble(sim) + Vector2(0.0, 1.5 * sim.band()))
	sim.advance(0.1)
	assert_bool(sim.out_of_band()).is_true()
	assert_float(_reach_px(display, ACTIVE)).is_greater(_band_px(display, ACTIVE))


func test_the_drawn_band_narrows_as_the_head_wears() -> void:
	var sim := _steady()
	var display := _display(sim)
	var fresh := _band_px(display, ACTIVE)

	DiveTestKit.wear_head_gently(sim, 0.6)
	sim.advance(0.1)

	assert_float(_band_px(display, ACTIVE)).is_less(fresh)
	assert_float(display.band_share()).is_equal_approx(sim.band() / sim.band_widest(), 0.0001)
	assert_float(display.band_share()).is_less(1.0)


func test_the_drawn_band_narrows_as_the_hull_heats_and_eases_as_it_cools() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))
	sim.advance(0.1)
	var display := _display(sim)
	var cool := _band_px(display, ACTIVE)

	sim.set_power(1.0)
	DiveTestKit.run(sim, 300.0)
	var hot := _band_px(display, ACTIVE)
	assert_float(hot).is_less(cool)

	sim.set_power(0.0)
	DiveTestKit.run(sim, 600.0)
	assert_float(_band_px(display, ACTIVE)).is_greater(hot)


# --- Wrong frequency and wrong amplitude look different ----------------------

func test_a_wrong_amplitude_draws_a_residual_of_one_size_and_a_wrong_frequency_one_that_swells_and_fades() -> void:
	var off_amplitude := _steady()
	DiveTestKit.tune(off_amplitude, ACTIVE, DiveTestKit.wobble(off_amplitude) + Vector2(0.0, 0.3))
	off_amplitude.advance(0.1)
	var off_frequency := _steady()
	DiveTestKit.tune(off_frequency, ACTIVE, DiveTestKit.wobble(off_frequency) + Vector2(0.3, 0.0))
	off_frequency.advance(0.1)

	var steady := _swells(_display(off_amplitude))
	var beating := _swells(_display(off_frequency))

	# Every swell of the one is about as tall as the next; the other's are not.
	assert_float(steady.min() / steady.max()).is_greater(0.9)
	assert_float(beating.min() / beating.max()).is_less(0.6)


## The height of each swell of ACTIVE's drawn Residual (each stretch between
## two crossings of the middle line), in pixels, left to right; the cut-off
## ones at the plot's ends left out.
func _swells(display: PlasmaDisplay) -> Array:
	var mid := display.residual_plot(ACTIVE).get_center().y
	var swells := []
	var tallest := 0.0
	var side := 0.0
	for point in display.residual_points(ACTIVE):
		var off := mid - point.y
		if side != 0.0 and signf(off) != side and off != 0.0:
			swells.append(tallest)
			tallest = 0.0
		if off != 0.0:
			side = signf(off)
		tallest = maxf(tallest, absf(off))
	swells.remove_at(0)
	assert_int(swells.size()).is_greater(3)
	return swells


# --- Every line, and the Band, carries its name ------------------------------

func test_each_lane_names_its_wobble_its_counter_wave_its_residual_and_the_band() -> void:
	var sim := _above_a_boundary()
	DiveTestKit.quiet_scan(sim)
	var display := _display(sim)

	var active := " | ".join(display.lane_texts(ACTIVE))
	var standby := " | ".join(display.lane_texts(STANDBY))
	for lane: String in [active, standby]:
		assert_str(lane).contains("WOBBLE")
		assert_str(lane).contains("COUNTER-WAVE")
		assert_str(lane).contains("BAND")
	assert_str(active).contains("ACTIVE")
	assert_str(active).contains("RESIDUAL")
	# STANDBY's are the scan's guess and what it predicts, and say so.
	assert_str(standby).contains("STANDBY")
	assert_str(standby).contains("WOBBLE GUESS")
	assert_str(standby).contains("PREDICTED")


func test_the_lane_the_controls_tune_is_marked_and_the_other_is_not() -> void:
	var sim := _steady()
	var display := _display(sim)
	assert_str(" | ".join(display.lane_texts(STANDBY))).contains(PlasmaDisplay.TUNING)
	assert_str(" | ".join(display.lane_texts(ACTIVE))).not_contains(PlasmaDisplay.TUNING)

	sim.select_channel(ACTIVE)
	display.refresh()

	assert_str(" | ".join(display.lane_texts(ACTIVE))).contains(PlasmaDisplay.TUNING)
	assert_str(" | ".join(display.lane_texts(STANDBY))).not_contains(PlasmaDisplay.TUNING)


## The instrument in each state that changes its words: no scan, a poor scan,
## a good one pretuned, a worn Head far out of the Band, just past a Boundary.
func _states() -> Array[DiveSimulation]:
	var unscanned := _above_a_boundary()
	var poor := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.basalt()], [30.0, DiveTestKit.rock(4.0)]]))
	poor.set_power(0.5)
	poor.pulse()
	poor.advance(0.1)
	assert_float(poor.wobble_ahead_spurious()).is_greater(0.0)
	assert_bool(is_nan(poor.residual(STANDBY))).is_false()
	var good := _above_a_boundary()
	DiveTestKit.quiet_scan(good, 6)
	DiveTestKit.tune(good, STANDBY, DiveTestKit.wobble_ahead(good))
	good.advance(0.1)
	var worn := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.basalt()], [100.0, DiveTestKit.rock(4.0)]]))
	DiveTestKit.wear_head_gently(worn, 0.8)
	worn.set_power(0.5)
	worn.select_channel(ACTIVE)
	DiveTestKit.tune(worn, ACTIVE, DiveTestKit.wobble(worn) + Vector2(0.0, 0.3))
	worn.advance(0.1)
	assert_bool(worn.plasma_lost()).is_false()
	var crossed := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.basalt()], [20.0, DiveTestKit.rock(4.0)]]))
	crossed.set_power(0.5)
	crossed.pulse()
	DiveTestKit.run_until(crossed, &"boundary_crossed", 600.0, [], 0.1)
	return [unscanned, poor, good, worn, crossed]


## A Label's words on the instrument: its place, less the empty top and
## bottom of a line of capitals.
func _words_rect(label: Label) -> Rect2:
	var whole := Rect2(label.position, label.get_minimum_size())
	return whole.grow_individual(0.0, -whole.size.y * 0.2, 0.0, -whole.size.y * 0.2)


func _showing(display: PlasmaDisplay) -> Array[Label]:
	var showing: Array[Label] = []
	for label in display.labels():
		if label.visible and not label.text.is_empty():
			showing.append(label)
	return showing


func test_every_word_of_the_instrument_lies_inside_it_and_none_over_another() -> void:
	for sim in _states():
		var display := _display(sim)
		await get_tree().process_frame
		display.refresh()
		var room := Rect2(Vector2.ZERO, display.size).grow(0.5)
		var showing := _showing(display)
		for label in showing:
			assert_bool(room.encloses(Rect2(label.position, label.get_minimum_size()))) \
					.override_failure_message("'%s' runs off the instrument" % label.text).is_true()
			for other in showing:
				if other != label:
					assert_bool(_words_rect(label).intersects(_words_rect(other))) \
							.override_failure_message("'%s' lies over '%s'" % [label.text, other.text]).is_false()
		remove_child(display)


func test_no_word_lies_over_a_plot() -> void:
	for sim in _states():
		var display := _display(sim)
		await get_tree().process_frame
		display.refresh()
		for label in _showing(display):
			for channel: StringName in [ACTIVE, STANDBY]:
				for plot: Rect2 in [display.waves_plot(channel), display.residual_plot(channel)]:
					assert_bool(_words_rect(label).intersects(plot)) \
							.override_failure_message("'%s' lies over a plot" % label.text).is_false()
		remove_child(display)


# --- The verdict, in words ---------------------------------------------------

func test_active_reads_inside_the_band_or_out_of_it_as_a_caution() -> void:
	assert_array(PlasmaDisplay.verdict(0.05, 0.2, 0.0, false)).is_equal(
			["RESIDUAL INSIDE THE BAND", StationTheme.NOW])
	assert_array(PlasmaDisplay.verdict(0.3, 0.2, 0.0, false)).is_equal(
			["RESIDUAL OUT OF THE BAND", StationTheme.CAUTION])


func test_standby_reads_a_prediction_and_says_when_only_the_scan_stands_behind_it() -> void:
	assert_array(PlasmaDisplay.verdict(NAN, 0.2, 0.3, true)).is_equal(
			["NO SCAN: NO PREDICTION", StationTheme.LEGEND])
	assert_array(PlasmaDisplay.verdict(0.3, 0.2, 0.0, true)).is_equal(
			["PREDICTED OUT OF THE BAND", StationTheme.CAUTION])
	assert_array(PlasmaDisplay.verdict(0.05, 0.2, 0.01, true)).is_equal(
			["PREDICTED INSIDE THE BAND", StationTheme.NOW])
	# Tuned to the guess, but the scan's own noise reaches outside the Band:
	# the line drawn ripples out of it, and the words do not call it safe.
	assert_array(PlasmaDisplay.verdict(0.05, 0.2, 0.3, true)).is_equal(
			["IN BAND IF THE SCAN IS RIGHT", StationTheme.NOW])


func test_standbys_verdict_follows_the_scan() -> void:
	var sim := _above_a_boundary()
	var display := _display(sim)
	assert_str(" | ".join(display.lane_texts(STANDBY))).contains("NO SCAN")

	DiveTestKit.quiet_scan(sim, 6)
	DiveTestKit.tune(sim, STANDBY, DiveTestKit.wobble_ahead(sim))
	sim.advance(0.1)
	display.refresh()

	assert_str(" | ".join(display.lane_texts(STANDBY))).contains("PREDICTED INSIDE THE BAND")


# --- The numbers beside the lines --------------------------------------------

func test_a_wave_reads_its_frequency_and_amplitude_and_a_dash_with_no_scan() -> void:
	assert_str(PlasmaDisplay.wave_text(1.234, 0.567)).is_equal("1.23 Hz x0.57")
	assert_str(PlasmaDisplay.wave_text(NAN, NAN)).is_equal("—")


func test_a_residual_reads_its_size_and_a_predicted_one_the_scans_noise_beside_it() -> void:
	assert_str(PlasmaDisplay.residual_text(0.456)).is_equal("RESIDUAL 0.46")
	assert_str(PlasmaDisplay.predicted_text(0.05, 0.214)).is_equal("PREDICTED 0.05 ±0.21")
	assert_str(PlasmaDisplay.predicted_text(0.05, 0.0)).is_equal("PREDICTED 0.05")
	assert_str(PlasmaDisplay.predicted_text(NAN, 0.3)).is_equal("PREDICTED —")


func test_the_scan_reads_how_sure_it_is_or_that_there_is_none() -> void:
	assert_str(PlasmaDisplay.sure_text(1.2, 0.62)).is_equal("GUESS SURE 62%")
	assert_str(PlasmaDisplay.sure_text(NAN, 0.0)).is_equal("NO SCAN AHEAD")


func test_the_predicted_residuals_plus_or_minus_is_the_scans_spurious_sines() -> void:
	var sim := _above_a_boundary()
	sim.pulse()
	sim.advance(0.1)
	var display := _display(sim)

	assert_str(" | ".join(display.lane_texts(STANDBY))).contains(
			PlasmaDisplay.predicted_text(sim.residual(STANDBY), sim.wobble_ahead_spurious()))


# --- Under the lanes ---------------------------------------------------------

func test_the_countdown_reads_its_plus_or_minus_and_beyond_five_minutes_when_the_scan_cannot_say() -> void:
	assert_str(PlasmaDisplay.countdown_text(42.4, 5.2, 300.0)).is_equal("BOUNDARY IN 42 s ±6")
	assert_str(PlasmaDisplay.countdown_text(125.0, 20.6, 300.0)).is_equal("BOUNDARY IN 125 s ±21")
	assert_str(PlasmaDisplay.countdown_text(INF, INF, 300.0)).is_equal("BOUNDARY > 5 min")


func test_the_countdown_gives_way_to_the_crossing_until_the_residual_is_back_in_the_band() -> void:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.basalt()], [20.0, DiveTestKit.rock(4.0)]]))
	sim.set_power(0.5)
	sim.advance(0.1)
	var display := _display(sim)
	assert_str(display.boundary_text()).contains("BOUNDARY")
	assert_str(display.boundary_text()).not_contains("CROSSED")
	assert_str(display.swap_text()).is_empty()
	assert_str(display.boundary_meaning()).is_equal(StationTheme.NOW)

	DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, [], 0.1)
	display.refresh()
	assert_str(display.boundary_text()).is_equal("BOUNDARY CROSSED")
	assert_str(display.swap_text()).contains(KeyMap.label(&"shift"))
	assert_array(Array(display.texts())).contains([display.swap_text()])
	assert_str(display.boundary_meaning()).is_equal(StationTheme.CAUTION)

	DiveTestKit.cancel_wobble(sim)
	sim.advance(0.1)
	display.refresh()
	assert_str(display.boundary_text()).not_contains("CROSSED")


func test_the_boundary_stands_along_the_track_where_the_countdown_puts_it() -> void:
	assert_float(PlasmaDisplay.track_place(0.0)).is_equal(0.0)
	assert_float(PlasmaDisplay.track_place(PlasmaDisplay.TRACK_S / 2.0)).is_equal_approx(0.5, 0.0001)
	assert_float(PlasmaDisplay.track_place(PlasmaDisplay.TRACK_S * 3.0)).is_equal(1.0)
	assert_float(PlasmaDisplay.track_place(INF)).is_equal(1.0)


func test_head_wear_reads_live() -> void:
	var sim := _steady()
	var display := _display(sim)
	assert_str(display.wear_text()).is_equal("HEAD WEAR 0%")

	DiveTestKit.wear_head_gently(sim, 0.37)
	display.refresh()

	assert_float(sim.head_wear()).is_between(0.37, 0.99)
	assert_str(display.wear_text()).is_equal("HEAD WEAR %d%%" % roundi(sim.head_wear() * 100.0))


func test_the_band_reads_beside_what_it_has_narrowed_from() -> void:
	assert_str(PlasmaDisplay.band_text(0.12, 0.2)).is_equal("BAND 0.12 OF 0.20")


func test_a_lost_plasma_shows_no_lanes_and_says_so() -> void:
	var sim := _steady()
	var display := _display(sim)
	DiveTestKit.lose_plasma(sim)
	display.refresh()

	assert_array(Array(display.lane_texts(ACTIVE))).is_empty()
	assert_array(Array(display.lane_texts(STANDBY))).is_empty()
	assert_array(Array(display.texts())).contains(["PLASMA LOST"])


func test_the_plus_or_minus_draws_in_the_screens_font() -> void:
	assert_bool(ThemeDB.fallback_font.has_char("±".unicode_at(0))).is_true()


func test_the_dash_draws_in_the_screens_font() -> void:
	assert_bool(ThemeDB.fallback_font.has_char("—".unicode_at(0))).is_true()


func test_with_no_wobble_on_the_plasma_activess_residual_reads_as_none() -> void:
	# A Glide, and the idle after it (ticket #123): ACTIVE has nothing to cancel.
	assert_str(PlasmaDisplay.residual_text(NAN)).not_contains("nan")
	assert_str(PlasmaDisplay.verdict(NAN, 0.2, 0.0, false)[0]).is_equal("NO WOBBLE ON THE PLASMA")

# The Glide seen, heard and felt (ticket #127): the melt in the Bore follows
# the Glide's state, replaces the Column exactly where the simulation has
# none and lights the room only from there; the roar rises and falls with the
# jet and plays nothing with no sound device; a staged moment repeats; the
# tunnel behind is told apart by its wall. Staged as a screenshot's tile is,
# on the First dive, which starts surveyed. Relationships, never tuned values.
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")
const STEP := 1.0 / 60.0


func _staged(seconds: float, commands: Array) -> Node3D:
	var args := ["--look", "bore", "--time", str(seconds), "--out", "unused.png"]
	for command: String in commands:
		args.append_array(["--do", command])
	return DiveTestKit.staged_shot(self, args)


func _gliding(seconds: float) -> Node3D:
	return _staged(seconds, ["1 plot_glide 400", "1 start_glide"])


func _lit(melt: BoreMelt) -> int:
	return melt.light_energies().filter(func(e: float) -> bool: return e > 0.0).size()


func test_before_any_glide_there_is_no_melt_and_no_melt_light() -> void:
	var habitat := _staged(5.0, ["0 set_power 0.5"])
	var melt: BoreMelt = habitat.bore_melt()

	assert_float(melt.radiance()).is_equal(0.0)
	assert_int(_lit(melt)).is_equal(0)
	for z in [-4.0, 0.0, 4.0]:
		assert_bool(melt.melt_at(Habitat.behind_head_at(z))).is_false()


func test_the_melt_brightens_through_the_spin_up_and_dims_as_the_jet_dies() -> void:
	var spinning := _gliding(1.5)
	var full := _gliding(6.0)
	var dropping := _staged(5.5, ["1 plot_glide 400", "1 start_glide", "4.5 drop_out_of_glide"])
	assert_float(spinning.simulation().glide_thrust()).is_less(full.simulation().glide_thrust())

	assert_float(spinning.bore_melt().radiance()).is_greater(0.0)
	assert_float(full.bore_melt().radiance()).is_greater(spinning.bore_melt().radiance())
	assert_float(dropping.bore_melt().radiance()).is_less(full.bore_melt().radiance())


func test_the_halted_melt_cools_at_the_idle_after_a_glide() -> void:
	var habitat := _staged(8.0, ["1 plot_glide 150", "1 start_glide"])
	var sim: DiveSimulation = habitat.simulation()
	var melt: BoreMelt = habitat.bore_melt()
	assert_str(sim.glide_state()).is_equal(DiveSimulation.GLIDE_IDLE)
	var just_halted := melt.radiance()

	for i in 600:
		habitat._physics_process(STEP)

	assert_float(just_halted).is_greater(0.0)
	assert_float(melt.radiance()).is_less(just_halted)
	assert_float(melt.radiance()).is_greater(0.0)  # Still glowing: a crust, not gone.
	assert_float(melt.temperature()).is_less(BoreMelt.SLOW_K)


func test_the_melt_and_its_light_are_exactly_where_the_simulation_has_no_column() -> void:
	# After a short Glide, spun up and crawling: Column comes in at the Head
	# end while the glided stretch is still in the Bore toward the Tail.
	var habitat := _staged(8.0, ["1 plot_glide 150", "1 start_glide", "7 shift", "7 set_power 1"])
	var sim: DiveSimulation = habitat.simulation()
	var melt: BoreMelt = habitat.bore_melt()
	var seen := {}
	for step in 4000:
		habitat._physics_process(STEP)
		for i in BoreMelt.LIGHTS:
			var z := -Habitat.LENGTH / 2.0 + (i + 0.5) * Habitat.LENGTH / BoreMelt.LIGHTS
			var absent := sim.column_absent(Habitat.behind_head_at(z))
			assert_bool(melt.melt_at(Habitat.behind_head_at(z))).is_equal(absent)
			assert_bool(melt.light_energies()[i] > 0.0).is_equal(absent)
			seen[absent] = true
		if seen.size() == 2 and not sim.column_absent(Habitat.behind_head_at(Habitat.LENGTH / 2.0)):
			break

	# Both melt and Column were in the Bore at once, and the melt has gone.
	assert_bool(seen.has(true) and seen.has(false)).is_true()
	assert_int(_lit(melt)).is_equal(0)


func test_the_melt_tints_the_room_and_blooms_only_while_lit() -> void:
	var crawling := _staged(5.0, ["0 set_power 0.5"])
	var gliding := _gliding(5.0)
	var calm: Environment = crawling.find_children("*", "WorldEnvironment", true, false)[0].environment
	var lit: Environment = gliding.find_children("*", "WorldEnvironment", true, false)[0].environment

	assert_bool(calm.glow_enabled).is_false()
	assert_bool(lit.glow_enabled).is_true()
	# Warmer: more red than blue in the melt's room than in the Crawl's.
	assert_float(lit.ambient_light_color.r - lit.ambient_light_color.b) \
			.is_greater(calm.ambient_light_color.r - calm.ambient_light_color.b)


func test_a_staged_glide_repeats() -> void:
	var one := _gliding(4.0)
	var two := _gliding(4.0)
	var material_one: ShaderMaterial = one.bore_melt()._material
	var material_two: ShaderMaterial = two.bore_melt()._material

	for parameter in [&"hot", &"cool", &"crusted", &"lump_phase", &"streak_phase", &"streaking"]:
		assert_that(material_one.get_shader_parameter(parameter)) \
				.is_equal(material_two.get_shader_parameter(parameter))
	assert_array(one.bore_melt().light_energies()).is_equal(two.bore_melt().light_energies())


func test_the_jet_shakes_the_crew_more_at_full_thrust_than_the_crawl() -> void:
	var crawling := _staged(5.0, ["0 set_power 0.5"])
	var gliding := _gliding(5.0)

	assert_float(gliding._shake_m).is_greater(crawling._shake_m)


# --- The roar ----------------------------------------------------------------

func test_the_roar_rises_in_loudness_and_pitch_with_the_jet() -> void:
	assert_float(JetRoar.loudness_db(0.0)).is_equal(JetRoar.SILENT_DB)
	assert_float(JetRoar.loudness_db(0.2)).is_greater(JetRoar.loudness_db(0.0))
	assert_float(JetRoar.loudness_db(1.0)).is_greater(JetRoar.loudness_db(0.2))
	assert_float(JetRoar.peak_hz(1.0)).is_greater(JetRoar.peak_hz(0.2))


func test_the_roar_plays_nothing_with_no_sound_device() -> void:
	var habitat := _gliding(5.0)
	var roars := habitat.find_children("*", "JetRoar", true, false)
	assert_int(roars.size()).is_equal(1)
	var roar: JetRoar = roars[0]

	assert_str(AudioServer.get_driver_name()).is_equal("Dummy")
	assert_bool(roar.playing).is_false()
	assert_object(roar.stream).is_null()


# --- The tunnel behind -------------------------------------------------------

func test_the_tunnel_look_tells_the_three_walls_apart() -> void:
	assert_that(TunnelLook.colour(DiveSimulation.TUNNEL_SEALED)) \
			.is_not_equal(TunnelLook.colour(DiveSimulation.TUNNEL_GLASS))
	assert_bool(StationTheme.has(TunnelLook.colour(DiveSimulation.TUNNEL_SEALED))).is_true()
	assert_bool(StationTheme.has(TunnelLook.colour(DiveSimulation.TUNNEL_GLASS))).is_true()
	var words := TunnelLook.WORDS.values()
	assert_int(words.size()).is_equal(3)
	assert_bool(words[0] != words[1] and words[1] != words[2] and words[0] != words[2]).is_true()


func test_after_a_glide_the_tunnel_behind_has_a_rough_stretch_run_on_to_the_tail() -> void:
	var habitat := _staged(40.0, ["1 plot_glide 150", "1 start_glide", "9 shift", "9 set_power 1"])
	var sim: DiveSimulation = habitat.simulation()
	var look := TunnelLook.new()
	var pieces := look.pieces(sim)
	var glided := sim.glided_stretches()[0]

	assert_str(TunnelLook.wall_at(pieces, (glided.x + glided.y) / 2.0)).is_equal(DiveSimulation.TUNNEL_ROUGH)
	assert_float(pieces.back().to).is_equal_approx(sim.distance() - sim.vessel_length(), 0.001)
	assert_str(TunnelLook.wall_at(pieces, sim.distance())).is_equal(&"")  # The vessel, not tunnel.

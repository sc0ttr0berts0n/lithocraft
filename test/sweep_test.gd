# Navigation's Sweep: the spiral scan of the forward hemisphere, tested at the
# simulation's interface. Assert relationships, never tuned constants
# (ADR 0001).
extends GdUnitTestSuite

## Where the Head starts in these tests, metres down, and the Boundaries just
## behind it and just ahead of it.
const START_M := 55.0
const BEHIND_M := 50.0
const AHEAD_M := 60.0


## Test values only: soft rock, a band of hard rock round where the Head
## starts, and soft again 5 m ahead of it, so a halted Sweep has a Boundary
## close behind (which it must never hear) and one close ahead, met by rays
## nearly square across within the shortest range. Far below, a Boundary
## beyond the shortest range but within the longest.
func _close() -> MediumLayout:
	return MediumLayout.layered([[0.0, DiveTestKit.soft()], [BEHIND_M, DiveTestKit.hard()],
			[AHEAD_M, DiveTestKit.soft()], [AHEAD_M + 150.0, DiveTestKit.hard()]])


## Test values only: soft rock down to a Boundary 45 m below where the Head
## starts, so a vessel under way through a whole Sweep at low power meets it
## only ahead.
func _open() -> MediumLayout:
	return MediumLayout.layered([[0.0, DiveTestKit.soft()], [START_M + 45.0, DiveTestKit.hard()]])


## A dive begun with the Head START_M down, the Reactor minding itself.
func _below(layout: MediumLayout) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.start_below(START_M)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	return sim


## Engages Quiet Ship and waits until the vessel is still and silent.
func _go_quiet(sim: DiveSimulation) -> void:
	sim.set_quiet_ship(true)
	for i in 600:
		sim.advance(0.1)
		if sim.speed() == 0.0 and sim.noise() == 0.0:
			return


## A halted, quiet vessel START_M down in _close(), its Sweep set to this
## range and begun.
func _quiet_sweep(range_m: float, width := DiveSimulation.BEAM_MIDDLE) -> DiveSimulation:
	var sim := _below(_close())
	_go_quiet(sim)
	sim.set_beam_width(width)
	sim.set_sweep_range(range_m)
	sim.start_sweep()
	return sim


## Runs on until the Sweep ends (or the time runs out); the seconds it took.
func _until_ended(sim: DiveSimulation, seconds := 600.0) -> float:
	var began := sim.dive_time()
	DiveTestKit.run_until(sim, &"sweep_ended", seconds, [], 0.5)
	return sim.dive_time() - began


## The points the dive's Sweeps returned, none of the Beam's or the survey's.
func _swept(sim: DiveSimulation) -> Array[ScanPoint]:
	return sim.points().filter(func(p: ScanPoint) -> bool: return p.pulse < 0 and not p.surveyed)


## Degrees between `axis` and the way a point lies from `origin`.
func _off_axis(point: ScanPoint, origin: Vector3, axis: Vector3) -> float:
	return rad_to_deg((point.position - origin).angle_to(axis))


func _shortest() -> float:
	return DiveSimulation.SWEEP_RANGES[0]


func _longest() -> float:
	return DiveSimulation.SWEEP_RANGES[-1]


func test_a_finished_sweep_returns_points_from_all_round_the_forward_hemisphere_and_none_from_behind() -> void:
	var sim := _quiet_sweep(_shortest())
	var origin := sim.head_position()

	_until_ended(sim)

	var points := _swept(sim)
	assert_bool(sim.sweep_running()).is_false()
	assert_int(points.size()).is_greater(0)
	var widest := 0.0
	var quarters := {}
	for point in points:
		var off := _off_axis(point, origin, Vector3.DOWN)
		widest = maxf(widest, off)
		var flat := point.position - origin
		quarters[Vector2i(signi(roundi(flat.x * 100.0)), signi(roundi(flat.z * 100.0)))] = true
		# Nothing from behind: the Boundary 5 m above the Head returns none.
		assert_float(off).is_less_equal(90.0)
		assert_float(-point.position.y).is_greater(START_M)
	# Out toward square across, and every quarter round the axis.
	assert_float(widest).is_greater(80.0)
	for quarter in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		assert_bool(quarters.has(quarter)).is_true()


func test_a_sweep_starts_at_the_edge_of_the_beam_s_cone() -> void:
	var middle := _quiet_sweep(_shortest())
	var narrow := _quiet_sweep(_shortest(), DiveSimulation.BEAM_NARROW)
	var origin := middle.head_position()
	assert_float(narrow.sweep_from_angle()).is_less(middle.sweep_from_angle())

	_until_ended(middle)
	_until_ended(narrow)

	var nearest := {}
	for sim: DiveSimulation in [middle, narrow]:
		nearest[sim] = 90.0
		for point in _swept(sim):
			nearest[sim] = minf(nearest[sim], _off_axis(point, origin, Vector3.DOWN))
	assert_float(nearest[narrow]).is_less(nearest[middle])
	assert_float(nearest[middle]).is_greater(middle.beam_half_angle() * 0.9)


func test_points_per_unit_of_angle_fall_from_ahead_toward_the_sides() -> void:
	# The Boundary 5 m ahead is met close by at every angle out to square
	# across, so the echoes are as strong ahead as at the sides and how many
	# come from each band of angle is how many rays went there.
	var sim := _quiet_sweep(_shortest(), DiveSimulation.BEAM_NARROW)
	var origin := sim.head_position()
	_until_ended(sim)
	var ahead := 0
	var aside := 0
	for point in _swept(sim):
		var off := _off_axis(point, origin, Vector3.DOWN)
		if off >= 20.0 and off < 40.0:
			ahead += 1
		elif off >= 65.0 and off < 85.0:
			aside += 1

	# Per unit of solid angle: a band's share of the sphere is 2 pi (cos a - cos b).
	var per_ahead := ahead / (cos(deg_to_rad(20.0)) - cos(deg_to_rad(40.0)))
	var per_aside := aside / (cos(deg_to_rad(65.0)) - cos(deg_to_rad(85.0)))
	assert_int(aside).is_greater(0)
	# Well clear of an even scan, whose ratio would be one.
	assert_float(per_ahead).is_greater(per_aside * 1.2)


func test_a_sweep_part_way_through_has_returned_only_the_inner_turns() -> void:
	var sim := _quiet_sweep(_shortest())
	var origin := sim.head_position()
	DiveTestKit.run(sim, sim.sweep_duration() * 0.5, 0.5)

	assert_bool(sim.sweep_running()).is_true()
	assert_float(sim.sweep_progress()).is_between(0.3, 0.7)
	var reached := sim.sweep_reached_angle()
	assert_float(reached).is_less(90.0)
	var part_way := _swept(sim)
	var widest_so_far := 0.0
	for point in part_way:
		widest_so_far = maxf(widest_so_far, _off_axis(point, origin, Vector3.DOWN))
	assert_int(part_way.size()).is_greater(0)
	assert_float(widest_so_far).is_less_equal(reached + 1.0)

	_until_ended(sim)

	var widest := 0.0
	for point in _swept(sim):
		widest = maxf(widest, _off_axis(point, origin, Vector3.DOWN))
	assert_int(_swept(sim).size()).is_greater(part_way.size())
	assert_float(widest).is_greater(widest_so_far + 10.0)


func test_its_points_arrive_as_it_goes() -> void:
	var sim := _quiet_sweep(_shortest())
	var counts: Array[int] = []
	for i in 4:
		DiveTestKit.run(sim, sim.sweep_duration() * 0.2, 0.5)
		counts.append(_swept(sim).size())

	assert_int(counts[0]).is_greater(0)
	for i in range(1, counts.size()):
		assert_int(counts[i]).is_greater(counts[i - 1])


## A Sweep to the shortest range from START_M in _open(): halted at Quiet
## Ship, or under way straight down at low power. The points it returned and
## how far down the Head went meanwhile.
func _sweep_of_open(under_way: bool) -> Array:
	var sim := _below(_open())
	if under_way:
		sim.set_power(0.3)
		DiveTestKit.run(sim, 5.0, 0.5)
	else:
		_go_quiet(sim)
	var from := sim.depth()
	sim.set_sweep_range(_shortest())
	sim.start_sweep()
	_until_ended(sim)
	assert_float(sim.depth()).is_less(START_M + 45.0)
	return [_swept(sim), sim.depth() - from]


## How far shallower than the Boundary the points lie, on average (negative
## when deeper), and how far off it they lie either way.
func _misplaced(points: Array) -> Vector2:
	var boundary := START_M + 45.0
	var shallower := 0.0
	var off := 0.0
	for point: ScanPoint in points:
		shallower += boundary + point.position.y
		off += absf(boundary + point.position.y)
	return Vector2(shallower, off) / maxf(points.size(), 1.0)


func test_a_sweep_under_way_places_its_points_less_truly_than_one_halted_at_quiet_ship() -> void:
	var halted: Array = _sweep_of_open(false)
	var moving: Array = _sweep_of_open(true)

	assert_float(halted[1]).is_equal(0.0)
	assert_float(moving[1]).is_greater(0.0)
	assert_int(halted[0].size()).is_greater(0)
	assert_int(moving[0].size()).is_greater(0)
	assert_float(_misplaced(moving[0]).y).is_greater(_misplaced(halted[0]).y)


func test_under_way_it_smears_by_the_way_the_vessel_moved_between_turns() -> void:
	# Each ray leaves from where the Head then is but is placed as if from
	# where the Sweep began, so diving toward the Boundary its echoes, heard
	# ever nearer, are drawn short of it: by half the descent on average, as
	# the rays go out evenly through the Sweep.
	var moving: Array = _sweep_of_open(true)
	var halted: Array = _sweep_of_open(false)

	assert_float(_misplaced(moving[0]).x).is_greater(moving[1] * 0.25)
	assert_float(_misplaced(moving[0]).x).is_less(moving[1] * 0.75)
	assert_float(absf(_misplaced(halted[0]).x)).is_less(moving[1] * 0.1)


func test_a_longer_range_takes_longer_and_reaches_further() -> void:
	var short := _quiet_sweep(_shortest())
	var long := _quiet_sweep(_longest())

	assert_float(long.sweep_duration()).is_greater(short.sweep_duration())
	var short_took := _until_ended(short)
	var long_took := _until_ended(long, 1200.0)

	assert_float(long_took).is_greater(short_took)
	assert_bool(long.sweep_running()).is_false()
	# The Boundary 150 m below the one ahead lies past the shortest range.
	var far := func(p: ScanPoint) -> bool: return -p.position.y > AHEAD_M + 100.0
	assert_int(_swept(short).filter(far).size()).is_equal(0)
	assert_int(_swept(long).filter(far).size()).is_greater(0)


func test_its_points_join_the_one_cloud_inside_its_bound() -> void:
	var sim := _below(_close())
	_go_quiet(sim)
	for i in 150:
		sim.pulse()
		sim.advance(0.1)
	var pulses := sim.points().size()
	sim.set_sweep_range(_shortest())
	sim.start_sweep()
	var most := 0
	for i in int(sim.sweep_duration() / 0.5) + 10:
		sim.advance(0.5)
		most = maxi(most, sim.point_count())

	assert_int(pulses).is_greater(0)
	assert_int(_swept(sim).size()).is_greater(0)
	assert_int(most).is_less_equal(sim.point_capacity())


func test_the_cloud_changes_with_each_batch_while_pulses_sent_counts_only_the_beam() -> void:
	var sim := _quiet_sweep(_shortest())
	var revision := sim.scan_revision()
	DiveTestKit.run(sim, sim.sweep_duration() * 0.5, 0.5)

	assert_int(sim.scan_revision()).is_greater(revision + 1)
	assert_int(sim.pulses_sent()).is_equal(0)


func test_a_stopped_sweep_keeps_what_it_heard_and_ends_short() -> void:
	var sim := _quiet_sweep(_shortest())
	DiveTestKit.run(sim, sim.sweep_duration() * 0.3, 0.5)
	sim.take_events()

	sim.stop_sweep()

	var ended := sim.take_events().filter(func(e: Dictionary) -> bool: return e.type == &"sweep_ended")
	assert_bool(sim.sweep_running()).is_false()
	assert_int(ended.size()).is_equal(1)
	assert_bool(ended[0].finished).is_false()
	assert_int(_swept(sim).size()).is_greater(0)


func test_starting_a_sweep_is_a_reading_and_its_range_a_setting() -> void:
	var sim := _below(_close())
	sim.set_autopilot(DiveSimulation.STATION_NAVIGATION, true)
	sim.start_sweep()
	assert_bool(sim.sweep_running()).is_true()
	assert_bool(sim.autopilot(DiveSimulation.STATION_NAVIGATION)).is_true()

	var other := _below(_close())
	other.set_autopilot(DiveSimulation.STATION_NAVIGATION, true)
	other.set_sweep_range(_longest())
	assert_float(other.sweep_range()).is_equal(_longest())
	assert_bool(other.autopilot(DiveSimulation.STATION_NAVIGATION)).is_false()


func test_a_running_sweep_keeps_its_range() -> void:
	var sim := _below(_close())
	sim.set_sweep_range(_shortest())
	sim.start_sweep()

	sim.set_sweep_range(_longest())

	assert_float(sim.sweep_range()).is_equal(_shortest())

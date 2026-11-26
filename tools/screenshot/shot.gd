## The screenshot tool's main loop, run by tools/screenshot/shot.sh (use
## that: it places the window, fixes the frame time and checks the result).
## Stages the shot its arguments ask for (ShotPlan), lets the view draw it,
## saves the PNG and quits: 0 with "SHOT OK" printed, 1 with the reason.
extends SceneTree

## Rendered frames between staging and the shot, at the fixed frame time the
## wrapper sets: enough for every display's SubViewport to be drawn and shown
## on its screen. Always the same number, so the same shot is the same picture.
const SETTLE_FRAMES := 8


func _initialize() -> void:
	# The view's shake draws on the global generator: the same every run.
	seed(0)
	var plan := ShotPlan.parse(OS.get_cmdline_user_args())
	if not plan.error.is_empty():
		_fail(plan.error)
		return
	var habitat := plan.make_habitat()
	root.add_child(habitat)
	if not habitat.is_node_ready():
		# The tree is only starting: staged as it becomes ready, before the
		# engine steps it.
		await habitat.ready
	var why := plan.stage(habitat)
	if not why.is_empty():
		_fail(why)
		return
	for frame in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("nothing was drawn (run windowed, not --headless)")
		return
	var saved := image.save_png(plan.out)
	if saved != OK:
		_fail("could not write %s (%s)" % [plan.out, error_string(saved)])
		return
	var sim: DiveSimulation = habitat.simulation()
	print("SHOT OK  %s  dive time %.2f s  depth %.1f m" % [
			sim.scenario_title(), sim.dive_time(), sim.depth()])
	quit(0)


func _fail(why: String) -> void:
	printerr("SHOT FAILED  %s" % why)
	quit(1)

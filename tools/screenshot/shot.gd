## The screenshot tool's main loop, run by tools/screenshot/shot.sh (use
## that: it places the window, fixes the frame time and checks the result).
## Stages the shot its arguments ask for (ShotPlan), lets the view draw it,
## saves the PNG and quits: 0 with "SHOT OK" printed, 1 with the reason.
## With --sheet it takes every shot of a list (ShotSheet) in this one run,
## each in a fresh Habitat, and saves them tiled into one labelled PNG.
extends SceneTree

## Rendered frames between staging and the shot, at the fixed frame time the
## wrapper sets: enough for every display's SubViewport to be drawn and shown
## on its screen. Always the same number, so the same shot is the same picture.
const SETTLE_FRAMES := 8
## A sheet's ground, its labels' names and, dimmer, their arguments.
const SHEET_GROUND := Color(0.08, 0.08, 0.09)
const LABEL_NAME := Color(1.0, 1.0, 1.0)
const LABEL_ARGUMENTS := Color(0.6, 0.62, 0.66)
const LABEL_FONT_SIZE := 20
const ARGUMENTS_FONT_SIZE := 14

## The Habitat of the shot last taken, and why a shot could not be.
var _habitat: Node3D = null
var _why := ""


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if "--sheet" in arguments:
		await _sheet(arguments)
	else:
		await _one(arguments)


func _one(arguments: PackedStringArray) -> void:
	var plan := ShotPlan.parse(arguments)
	if not plan.error.is_empty():
		_fail(plan.error)
		return
	var image := await _take(plan)
	if image == null:
		_fail(_why)
		return
	if not _save(image, plan.out):
		return
	var sim: DiveSimulation = _habitat.simulation()
	print("SHOT OK  %s  dive time %.2f s  depth %.1f m" % [
			sim.scenario_title(), sim.dive_time(), sim.depth()])
	quit(0)


func _sheet(arguments: PackedStringArray) -> void:
	var sheet := ShotSheet.parse(arguments)
	if not sheet.error.is_empty():
		_fail(sheet.error)
		return
	var tiles: Array[Image] = []
	for shot in sheet.shots:
		var image := await _take(shot.plan)
		if image == null:
			_fail("shot '%s': %s" % [shot.name, _why])
			return
		tiles.append(image)
		# Gone before the next shot's Habitat comes, so each is alone.
		_habitat.free()
	var page := await _tiled(sheet, tiles)
	if not _save(page, sheet.out):
		return
	print("SHOT OK  sheet of %d shots  %d x %d" % [tiles.size(), page.get_width(), page.get_height()])
	quit(0)


## One shot: a fresh Habitat staged for the plan and drawn, left in _habitat.
## Returns null, with _why set, if it could not be taken.
func _take(plan: ShotPlan) -> Image:
	# The view's shake draws on the global generator: the same every shot.
	seed(0)
	_habitat = plan.make_habitat()
	root.add_child(_habitat)
	if not _habitat.is_node_ready():
		# The tree is only starting: staged as it becomes ready, before the
		# engine steps it.
		await _habitat.ready
	_why = plan.stage(_habitat)
	if not _why.is_empty():
		return null
	for frame in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_why = "nothing was drawn (run windowed, not --headless)"
		return null
	return image


## The sheet's picture: each shot scaled to a tile and set where the sheet
## lays it out, its name and arguments in the label over it. Drawn by a
## viewport of the sheet's own size, so it can be larger than the window.
func _tiled(sheet: ShotSheet, tiles: Array[Image]) -> Image:
	sheet.lay_out(tiles[0].get_size())
	var page := SubViewport.new()
	page.size = sheet.size()
	page.disable_3d = true
	page.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var ground := ColorRect.new()
	ground.color = SHEET_GROUND
	ground.size = page.size
	page.add_child(ground)
	for i in tiles.size():
		var tile := tiles[i]
		if tile.get_size() != sheet.tile:
			tile.resize(sheet.tile.x, sheet.tile.y, Image.INTERPOLATE_LANCZOS)
		var picture := TextureRect.new()
		picture.texture = ImageTexture.create_from_image(tile)
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.position = sheet.tile_rect(i).position
		page.add_child(picture)
		var label := HBoxContainer.new()
		label.add_theme_constant_override("separation", 14)
		label.position = sheet.label_rect(i).position
		label.size = sheet.label_rect(i).size
		label.add_child(_text(sheet.shots[i].name, LABEL_FONT_SIZE, LABEL_NAME))
		var arguments := _text(sheet.shots[i].arguments, ARGUMENTS_FONT_SIZE, LABEL_ARGUMENTS)
		arguments.clip_text = true
		arguments.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_child(arguments)
		page.add_child(label)
	root.add_child(page)
	for frame in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := page.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	return image


func _text(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = font_size
	label.label_settings.font_color = color
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return label


func _save(image: Image, path: String) -> bool:
	var saved := image.save_png(path)
	if saved != OK:
		_fail("could not write %s (%s)" % [path, error_string(saved)])
	return saved == OK


func _fail(why: String) -> void:
	printerr("SHOT FAILED  %s" % why)
	quit(1)

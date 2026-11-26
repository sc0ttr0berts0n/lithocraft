## A Station hung on a gimbal at its pivot. It swings so its own up follows
## the crew's "up", lagging a little so the swing can be seen, and turns
## about that up so its screen faces the Bore: the crew work it from the
## Bore side, looking out at it with the outer wall behind the screen.
## Without a name it is an empty mount: the gimbal with no Station on it.
class_name GimballedStation
extends Node3D

## How quickly the gimbal settles onto a new "up", per second.
const SWING_RATE := 3.0
## Below this share of the screen's distance from the Bore axis, the way to
## the axis across "up" is too short to face along: the axis is straight
## above or below.
const FACING_FREE := 0.05
## Middle of the screen, in the cradle's frame.
const SCREEN_CENTRE := Vector3(0, 0.2, 0)
## Eyes of a crew member working the Station, in the cradle's frame: in front
## of the screen and at standing eye height (1.65 m) above a floor 1.1 m
## below the pivot.
const POSE_EYE := Vector3(0, 0.55, -0.85)
## The screen's size and colour; the key panel beside it matches.
const SCREEN_SIZE := Vector2(0.8, 0.4)
const SCREEN_COLOUR := Color(0.04, 0.07, 0.09)
## Share of the screen the text may fill, leaving a margin round it, and the
## text's size in metres per font pixel.
const SCREEN_TEXT_FILL := 0.94
const SCREEN_TEXT_PIXEL := 0.0015
## The live pictures' room on the screen (show_display(), show_displays()),
## and the gap between pictures side by side.
const DISPLAY_SIZE := Vector2(0.76, 0.36)
const DISPLAY_GAP := 0.01
## The key panel: its gap from the screen, its width, one row's height, a key
## prompt's size, and the size of what each key does.
const KEYS_GAP := 0.02
const KEYS_WIDTH := 0.64
const KEY_ROW_M := 0.058
const KEY_SIZE_M := 0.052
const KEY_TEXT_PIXEL := 0.001
const KEY_FONT_SIZE := 32

var station_name := ""
var hue := Color.WHITE
## Font size of the screen's text; smaller fits more lines on the screen. A
## reading too big for the screen at this size is shrunk until it fits.
var screen_font_size := 48

## Seconds between call beats at the least and the most urgent, and the call
## light's brightest energy (on each beat; it fades between them).
const CALL_BEAT_CALM_S := 1.4
const CALL_BEAT_URGENT_S := 0.3
const CALL_LIGHT_ENERGY := 2.5
const CALL_LIGHT_FADE_S := 0.25
## How far up the call tone climbs at full urgency, as a pitch scale.
const CALL_PITCH_RISE := 0.5
## Sample rate and pip shape of the call tone.
const _TONE_RATE := 22050
const _PIP_S := 0.08
const _PIP_GAP_S := 0.06

## The autopilot's disconnect warning: a falling run of notes (hertz), each
## this long, the same at every Station so it is never taken for a call; it
## comes from the Station that let go. After it the screen's AUTOPILOT OFF
## flashes for a while, blinking at this rate. Real basis: an airliner's
## autopilot disconnect is a distinct aural warning with a flashing caption.
const DISENGAGE_NOTES: Array[float] = [1175.0, 880.0, 659.0]
const _DISENGAGE_NOTE_S := 0.11
const DISENGAGE_FLASH_S := 3.0
const DISENGAGE_BLINK_S := 0.25

## The Station's call: its own tone (base frequency in hertz) and the number of
## pips in each beat, so each Station sounds different. Set before _ready.
var call_tone_hz := 440.0
var call_pips := 1
## Text shown under the reading, e.g. the time rate. Every Station shows it.
var footer := ""

var _cradle := Node3D.new()
## False until the first follow_up(), which settles the cradle at once
## rather than swinging it in from where it was built.
var _settled := false
var _screen_text: Label3D
## The live pictures on the screen, left to right as the crew see them, if
## show_display() or show_displays() put any there; and a lone picture's
## instruments' names and places on the face, in the order show_display()
## had them.
var _displays: Array[MeshInstance3D] = []
var _instrument_names: Array[StringName] = []
var _instrument_places: Array[Rect2] = []
var _call_light: OmniLight3D
var _call_sound: AudioStreamPlayer3D
var _disengage_sound: AudioStreamPlayer3D
## Whether this Station's autopilot is engaged (the Habitat sets it each
## frame from the simulation), and seconds since it last let go.
var autopilot := false
var _since_disengaged := INF
## How urgently the Station calls, 0 (not calling) to 1.
var _urgency := 0.0
var _until_beat := 0.0
## Share of the power it asks for the Station is getting, 0 to 1. Below 1 its
## screen browns out: dimmer the less it gets, and flickering.
var _supplied := 1.0
var _flicker := RandomNumberGenerator.new()
## The key panel's prompts and words, each with its own colour, so they dim
## with the screen: [node, colour].
var _key_parts: Array = []


func _ready() -> void:
	add_child(_cradle)
	_add_yoke()
	if station_name.is_empty():
		return
	var desk := MeshInstance3D.new()
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(0.9, 0.04, 0.5)
	desk.mesh = desk_mesh
	desk.material_override = _material(Color(0.29, 0.34, 0.37))
	desk.position = Vector3(0, -0.08, 0)
	_cradle.add_child(desk)

	var screen := MeshInstance3D.new()
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(SCREEN_SIZE.x, SCREEN_SIZE.y, 0.02)
	screen.mesh = screen_mesh
	screen.material_override = _material(SCREEN_COLOUR)
	screen.position = SCREEN_CENTRE
	_cradle.add_child(screen)

	# The screen faces the cradle's -z, out from the Bore; the crew work it
	# from that side.
	_screen_text = Label3D.new()
	_screen_text.text = station_name
	_screen_text.modulate = hue
	_screen_text.pixel_size = SCREEN_TEXT_PIXEL
	_screen_text.font_size = screen_font_size
	_screen_text.position = SCREEN_CENTRE + Vector3(0, 0, -0.015)
	_screen_text.rotation = Vector3(0, PI, 0)
	_cradle.add_child(_screen_text)

	# The Station's own light, dark until it calls for attention.
	_call_light = OmniLight3D.new()
	_call_light.light_color = hue
	_call_light.light_energy = 0.0
	_call_light.omni_range = 2.5
	_call_light.position = Vector3(0, 0.5, -0.3)
	_cradle.add_child(_call_light)

	# Its own tone, from where it hangs, so the ring tells the ear which way.
	_call_sound = AudioStreamPlayer3D.new()
	_call_sound.stream = _call_tone()
	_call_sound.unit_size = 2.0
	_call_sound.position = SCREEN_CENTRE
	_cradle.add_child(_call_sound)
	_disengage_sound = AudioStreamPlayer3D.new()
	_disengage_sound.stream = _disengage_tone()
	_disengage_sound.unit_size = 2.0
	_disengage_sound.position = SCREEN_CENTRE
	_cradle.add_child(_disengage_sound)


func _process(delta: float) -> void:
	if not _call_light:
		return
	_since_disengaged += delta
	var dim := 1.0
	if _supplied < 1.0:
		dim = lerpf(0.25, 0.8, _supplied) * _flicker.randf_range(0.6, 1.0)
	_screen_text.modulate = Color(hue * dim, 1.0)
	for part in _key_parts:
		part[0].modulate = Color(part[1] * dim, 1.0)
	_call_light.light_energy *= exp(-delta / CALL_LIGHT_FADE_S)
	if _urgency <= 0.0:
		_until_beat = 0.0
		return
	_until_beat -= delta
	if _until_beat <= 0.0:
		_until_beat = beat_seconds(_urgency)
		_call_light.light_energy = CALL_LIGHT_ENERGY
		_call_sound.pitch_scale = pitch_scale(_urgency)
		_call_sound.play()


## Call for attention, 0 (stop) to 1 (most urgent): a beat of the Station's
## own tone and a flash of its own light, faster and higher the more urgent.
## Nothing is drawn over the view; the screen says why.
func set_call(urgency: float) -> void:
	_urgency = clampf(urgency, 0.0, 1.0)


func is_calling() -> bool:
	return _urgency > 0.0


## The Station's autopilot has just let go: the disconnect warning sounds
## here, and AUTOPILOT OFF flashes on the screen.
func autopilot_off() -> void:
	_since_disengaged = 0.0
	if _disengage_sound:
		_disengage_sound.play()


## The autopilot's word on the screen's top line: AUTOPILOT while engaged,
## AUTOPILOT OFF while not, blinking for DISENGAGE_FLASH_S after it let go
## (blank in the blink's off half).
static func autopilot_caption(engaged: bool, since_disengaged: float) -> String:
	if engaged:
		return "AUTOPILOT"
	if since_disengaged < DISENGAGE_FLASH_S \
			and fmod(since_disengaged, 2.0 * DISENGAGE_BLINK_S) >= DISENGAGE_BLINK_S:
		return ""
	return "AUTOPILOT OFF"


## Seconds between beats of a call this urgent.
static func beat_seconds(urgency: float) -> float:
	return lerpf(CALL_BEAT_CALM_S, CALL_BEAT_URGENT_S, clampf(urgency, 0.0, 1.0))


## Pitch scale of the call tone for a call this urgent.
static func pitch_scale(urgency: float) -> float:
	return 1.0 + CALL_PITCH_RISE * clampf(urgency, 0.0, 1.0)


## One beat of the call: call_pips short pips of the Station's tone, with a
## little of its octave so it carries, each faded in and out to avoid clicks.
func _call_tone() -> AudioStreamWAV:
	var pip := int(_PIP_S * _TONE_RATE)
	var gap := int(_PIP_GAP_S * _TONE_RATE)
	var frames := call_pips * (pip + gap)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var in_pip := i % (pip + gap)
		var value := 0.0
		if in_pip < pip:
			var t := float(i) / _TONE_RATE
			var envelope := minf(1.0, minf(in_pip, pip - in_pip) / (0.01 * _TONE_RATE))
			value = envelope * (0.8 * sin(TAU * call_tone_hz * t) + 0.2 * sin(TAU * 2.0 * call_tone_hz * t))
		data.encode_s16(i * 2, int(value * 0.6 * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = _TONE_RATE
	wav.stereo = false
	wav.data = data
	return wav


## The disconnect warning: DISENGAGE_NOTES one after another, each faded in
## and out to avoid clicks.
static func _disengage_tone() -> AudioStreamWAV:
	var note := int(_DISENGAGE_NOTE_S * _TONE_RATE)
	var data := PackedByteArray()
	data.resize(DISENGAGE_NOTES.size() * note * 2)
	for n in DISENGAGE_NOTES.size():
		for i in note:
			var t := float(i) / _TONE_RATE
			var envelope := minf(1.0, minf(i, note - i) / (0.01 * _TONE_RATE))
			var value := envelope * sin(TAU * DISENGAGE_NOTES[n] * t)
			data.encode_s16((n * note + i) * 2, int(value * 0.6 * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = _TONE_RATE
	wav.stereo = false
	wav.data = data
	return wav


## Tell the Station what share of the power it asks for it is getting, 0 to 1.
## Starved (below 1), its screen dims and flickers so it shows at the Station.
func set_supplied(share: float) -> void:
	_supplied = clampf(share, 0.0, 1.0)


func is_starved() -> bool:
	return _supplied < 1.0


## Text shown on the Station's screen, under its name and its autopilot's
## caption. On a text screen (no display) the font shrinks as needed so every
## line fits on the screen.
func show_reading(text: String) -> void:
	if not _screen_text:
		return
	_screen_text.text = "%s   %s\n%s%s" % [station_name,
			autopilot_caption(autopilot, _since_disengaged), text,
			"" if footer.is_empty() else "\n" + footer]
	if _displays.is_empty():
		_screen_text.font_size = fitting_font_size(_screen_text.text, _screen_font(),
				screen_font_size, _text_box())


## The largest font size, up to largest, at which text (centred lines) fits
## inside box, in font pixels. Never below 1.
static func fitting_font_size(text: String, font: Font, largest: int, box: Vector2) -> int:
	var size := largest
	while size > 1:
		var block := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
		if block.x <= box.x and block.y <= box.y:
			break
		size -= 1
	return size


func _screen_font() -> Font:
	return _screen_text.font if _screen_text.font else ThemeDB.fallback_font


## The room for text on the screen in font pixels, less a margin and the
## text's outline.
func _text_box() -> Vector2:
	var outline := 2.0 * _screen_text.outline_size
	return SCREEN_SIZE * SCREEN_TEXT_FILL / SCREEN_TEXT_PIXEL - Vector2(outline, outline)


## Where a crew member's eyes are held to work this Station, Habitat frame:
## origin at the eyes, basis upright with the cradle, facing the screen.
func pose() -> Transform3D:
	return pose_for(position, _cradle.basis)


## The middle of this Station's screen, Habitat frame.
func screen_centre() -> Vector3:
	return screen_centre_for(position, _cradle.basis)


## The working pose of a Station pivoting at pivot with its cradle at cradle.
## The eyes are where a person standing STATION_HANG below the pivot would
## have them, on the cradle's -z side, as the screen faces that way.
static func pose_for(pivot: Vector3, cradle: Basis) -> Transform3D:
	var facing_screen := cradle * Basis(Vector3.UP, PI)
	return Transform3D(facing_screen, pivot + cradle * POSE_EYE)


static func screen_centre_for(pivot: Vector3, cradle: Basis) -> Vector3:
	return pivot + cradle * SCREEN_CENTRE


## How far to look down from level, in radians, to see the screen from the pose.
static func pose_look() -> float:
	return -atan2(POSE_EYE.y - SCREEN_CENTRE.y, -POSE_EYE.z)


## This Station's screen as the centre dot sees it (Habitat frame), with its
## readings: one per line of its screen text, the name first, then its
## displays if it shows any, left to right, then each of a lone display's
## instruments, which lie over it (see reading(), is_display(),
## display_index(), instrument()). An empty mount has no readings.
func face() -> Pointing.Face:
	var screen := face_for(position, _cradle.basis)
	if _screen_text == null:
		return screen
	var font := _screen_text.font if _screen_text.font else ThemeDB.fallback_font
	var line_m := (font.get_height(_screen_text.font_size) + _screen_text.line_spacing) \
			* _screen_text.pixel_size
	var lines := _lines()
	# The text's top edge, in face coordinates: centred on its place, or
	# standing on it when set above a display.
	var top := _screen_text.position.y - SCREEN_CENTRE.y
	if _screen_text.vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
		top += line_m * lines.size() / 2.0
	elif _screen_text.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM:
		top += line_m * lines.size()
	for i in lines.size():
		screen.readings.append(Rect2(-SCREEN_SIZE.x / 2.0, top - line_m * (i + 1), SCREEN_SIZE.x, line_m))
	for d in _displays.size():
		screen.readings.append(display_rect(d, _displays.size()))
	screen.readings.append_array(_instrument_places)
	return screen


## The place of display `index` of `count` side by side, in face
## coordinates: sharing DISPLAY_SIZE equally, the first on the crew's left.
static func display_rect(index: int, count: int) -> Rect2:
	var width := (DISPLAY_SIZE.x - DISPLAY_GAP * (count - 1)) / count
	return Rect2(-DISPLAY_SIZE.x / 2.0 + index * (width + DISPLAY_GAP), -DISPLAY_SIZE.y / 2.0,
			width, DISPLAY_SIZE.y)


## What the reading at this index of face().readings shows: its line of
## screen text, or "" for a display.
func reading(index: int) -> String:
	var lines := _lines()
	return lines[index] if index >= 0 and index < lines.size() else ""


## True if the reading at this index of face().readings is a display: they
## come after the last line of text.
func is_display(index: int) -> bool:
	return display_index(index) >= 0


## Which display the reading at this index of face().readings is, counting
## from the crew's left (the order given to show_displays()), or -1 for a
## line of text or nothing.
func display_index(index: int) -> int:
	var d := index - _lines().size()
	return d if d >= 0 and d < _displays.size() else -1


## The name of the display's instrument at this index of face().readings
## (as show_display() was given it), or &"" for anything else.
func instrument(index: int) -> StringName:
	var i := index - _lines().size() - _displays.size()
	return _instrument_names[i] if i >= 0 and i < _instrument_names.size() else &""


## The screen text's lines, the name first; none on an empty mount.
func _lines() -> PackedStringArray:
	return _screen_text.text.split("\n") if _screen_text else PackedStringArray()


## The screen of a Station pivoting at pivot with its cradle at cradle, as a
## face with no readings: facing the working pose, the crew's right as x.
static func face_for(pivot: Vector3, cradle: Basis) -> Pointing.Face:
	var screen := Pointing.Face.new()
	# The screen box's front, on the Head side where its text faces.
	var front := SCREEN_CENTRE + Vector3(0, 0, -0.01)
	screen.transform = Transform3D(cradle * Basis(Vector3.UP, PI), pivot + cradle * front)
	screen.bounds = Rect2(-SCREEN_SIZE / 2.0, SCREEN_SIZE)
	return screen


## Show a live picture (e.g. a SubViewport's texture) filling the Station's
## screen. The name and reading move above the screen. instruments names the
## picture's instruments, each a reading of its own: {name: its place as
## shares of the picture, 0 to 1 across from the left and down from the top}.
func show_display(texture: Texture2D, instruments: Dictionary = {}) -> void:
	if _screen_text == null:
		return
	_instrument_names = []
	_instrument_places = []
	for name: StringName in instruments:
		var share: Rect2 = instruments[name]
		# Face coordinates: x the crew's right, y up, origin at the middle.
		var place := Rect2(Vector2(share.position.x - 0.5, 0.5 - share.end.y) * DISPLAY_SIZE,
				share.size * DISPLAY_SIZE)
		_instrument_names.append(name)
		_instrument_places.append(place)
	var textures: Array[Texture2D] = [texture]
	show_displays(textures)


## Show live pictures side by side on the Station's screen, the first on the
## crew's left, sharing it equally (display_rect()); each is its own reading.
## Their textures should match that shape. The name and reading move above
## the screen. Once only, as the Station is built.
func show_displays(textures: Array[Texture2D]) -> void:
	if _screen_text == null:
		return
	for d in textures.size():
		var rect := display_rect(d, textures.size())
		var display := MeshInstance3D.new()
		_displays.append(display)
		var quad := QuadMesh.new()
		quad.size = rect.size
		display.mesh = quad
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_texture = textures[d]
		display.material_override = material
		# Faces the crew, like the text; turned to face them, the crew's
		# right is the cradle's -x.
		display.position = SCREEN_CENTRE + Vector3(-rect.get_center().x, rect.get_center().y, -0.012)
		display.rotation = Vector3(0, PI, 0)
		_cradle.add_child(display)
	_screen_text.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_screen_text.position.y = 0.42


## Show the Station's keys on a panel beside its screen, on the crew's right
## as they work it: each binding's key prompts, then what it does. Pass
## KeyMap.bindings_at(<this Station>), so the panel is the key map.
func show_keys(bindings: Array[Dictionary]) -> void:
	if _screen_text == null:
		return
	# The screen text is turned to face the cradle's -z, so the crew's right
	# is -x.
	var right_edge := -KEYS_GAP - SCREEN_SIZE.x / 2.0
	var board := MeshInstance3D.new()
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(KEYS_WIDTH, SCREEN_SIZE.y, 0.02)
	board.mesh = board_mesh
	board.material_override = _material(SCREEN_COLOUR)
	board.position = SCREEN_CENTRE + Vector3(right_edge - KEYS_WIDTH / 2.0, 0, 0)
	_cradle.add_child(board)
	var left := right_edge - KEY_ROW_M / 2.0
	var y := SCREEN_CENTRE.y + SCREEN_SIZE.y / 2.0 - KEY_ROW_M * 0.8
	for binding in bindings:
		var x := left
		for code: int in KeyPrompt.distinct(binding.keys):
			var key := Sprite3D.new()
			key.texture = KeyPrompt.texture(code)
			key.pixel_size = KEY_SIZE_M / key.texture.get_width()
			key.position = Vector3(x - KEY_SIZE_M / 2.0, y, -0.012)
			key.rotation = Vector3(0, PI, 0)
			_cradle.add_child(key)
			_key_parts.append([key, Color.WHITE])
			var glyph := KeyPrompt.glyph(code)
			if not glyph.is_empty():
				var mark := _key_text(glyph, Color.BLACK)
				mark.position = key.position + Vector3(0, 0, -0.001)
				_cradle.add_child(mark)
			x -= KEY_SIZE_M * 1.08
		var does := _key_text(binding.does, hue)
		does.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		does.position = Vector3(x - 0.01, y, -0.012)
		_cradle.add_child(does)
		_key_parts.append([does, hue])
		y -= KEY_ROW_M


func _key_text(text: String, colour: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.modulate = colour
	label.outline_size = 0
	label.pixel_size = KEY_TEXT_PIXEL
	label.font_size = KEY_FONT_SIZE
	label.rotation = Vector3(0, PI, 0)
	return label


## Swing toward the given "up" (Habitat frame, unit length), turning to
## face the Bore as settled_cradle() says. The first call settles at once.
func follow_up(up: Vector3, dt: float) -> void:
	if up.is_zero_approx():
		return  # nothing felt (a lurch cancelling gravity): hold as it is
	var settled := settled_cradle(position, up, _cradle.basis)
	var weight := 1.0 - exp(-dt * SWING_RATE) if _settled else 1.0
	_settled = true
	_cradle.basis = Basis(_cradle.basis.get_rotation_quaternion().slerp(
			settled.get_rotation_quaternion(), weight)).orthonormalized()


## Where the cradle of a Station pivoting at pivot settles for this "up"
## (Habitat frame): upright, and turned about up so its +z, the way the crew
## look through the screen, points from the screen away from the Bore axis
## as squarely as upright allows: the screen faces the Bore. The third gimbal ring that turns it is
## driven, not free. With the axis straight above or below the screen there
## is no such turn, and it keeps the heading it had (from).
static func settled_cradle(pivot: Vector3, up: Vector3, from: Basis) -> Basis:
	var upright := Gimbal.toward_up(from, up, 1.0)
	var screen := screen_centre_for(pivot, upright)
	var toward_axis := Vector3(-screen.x, -screen.y, 0.0)
	var across := toward_axis - upright.y * toward_axis.dot(upright.y)
	if across.length() < FACING_FREE * toward_axis.length():
		return upright
	var look := -across.normalized()
	return Basis(upright.y.cross(look), upright.y, look)


func _add_yoke() -> void:
	# A ring at the pivot so the gimbal itself is visible.
	var yoke := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.1
	ring.outer_radius = 0.13
	yoke.mesh = ring
	yoke.material_override = _material(Color(0.54, 0.6, 0.64))
	yoke.rotation = Vector3(PI / 2, 0, 0)
	add_child(yoke)
	var bob := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	bob.mesh = sphere
	bob.material_override = _material(hue if not station_name.is_empty() else Color(0.4, 0.4, 0.4))
	_cradle.add_child(bob)


static func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	return m

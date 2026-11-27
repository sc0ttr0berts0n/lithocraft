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
## Middle of the screen, in the cradle's frame: its foot stands just clear of
## the gimbal's bob, and its top stays inside the outer wall wherever the
## Station hangs.
const SCREEN_CENTRE := Vector3(0, 0.42, 0)
## Eyes of a crew member working the Station, in the cradle's frame: in front
## of the screen and a little above its middle. The Arm holds them here; the
## floor is the ring's working height below the pivot (the Habitat's
## RING_ABOVE_HEAD_FLOOR), so the hold is some 0.2 m above standing eye height
## (1.65 m) and the feet hang clear of it.
const POSE_EYE := Vector3(0, 0.55, -0.85)
## The screen's size, the shape of StationScreen.SIZE: large enough that from
## the working pose the whole of it is in view and its text reads. The casing
## round it and round the key panel is this much wider, and this colour.
const SCREEN_SIZE := Vector2(1.2, 0.72)
const CASING := 0.015
const CASING_COLOUR := Color(0.04, 0.07, 0.09)
## The key panel beside the screen, on the crew's right: its gap from the
## screen and its width, the shape of KeyList.SIZE at the screen's scale. It
## is as tall as the screen.
const KEYS_GAP := 0.03
const KEYS_WIDTH := 0.48

var station_name := ""
## The Station's own colour, for its call light and the bob on its gimbal.
## Nothing on its screen is drawn in it: a screen's colours are StationTheme's.
var hue := Color.WHITE

## Seconds between call beats at the least and the most urgent, and the call
## light's brightest energy (on each beat; it fades between them).
const CALL_BEAT_CALM_S := 1.4
const CALL_BEAT_URGENT_S := 0.3
const CALL_LIGHT_ENERGY := 2.5
const CALL_LIGHT_FADE_S := 0.25
## The call light's glow, held steady, while its call shows but does not
## sound: acknowledged, or a feature's chime rung. Dimmer than a beat's flash.
const CALL_LIGHT_HELD_ENERGY := 0.8
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
## Soft, since it sounds every time the crew takes a Station back: no note
## above the Stations' own call tones, each swelling and dying away with no
## edge, and quieter than a call (DISENGAGE_LEVEL against CALL_LEVEL).
const DISENGAGE_NOTES: Array[float] = [523.0, 415.0, 330.0]
const _DISENGAGE_NOTE_S := 0.16
const DISENGAGE_LEVEL := 0.25
const CALL_LEVEL := 0.6
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
## The screen's frame (its header strip, the Station's instrument, its
## status lines) and the key list beside it, each drawn in its own viewport
## and shown on a panel; null on an empty mount.
var _screen: StationScreen
var _screen_material: StandardMaterial3D
var _keys: KeyList
var _keys_material: StandardMaterial3D
## A lone picture's instruments, in the order show_display() had them: their
## names, and each one's place as shares of the picture.
var _instrument_names: Array[StringName] = []
var _instrument_shares: Array[Rect2] = []
var _call_light: OmniLight3D
var _call_sound: AudioStreamPlayer3D
var _disengage_sound: AudioStreamPlayer3D
## Whether this Station's autopilot is engaged (the Habitat sets it each
## frame from the simulation), and seconds since it last let go.
var autopilot := false
var _since_disengaged := INF
## How urgently the Station calls, 0 (not calling) to 1; whether the call
## sounds (not yet acknowledged) and whether it is a warning, which beats,
## or a report, which chimes once.
var _urgency := 0.0
var _sounding := false
var _warns := true
var _chimed := false
var _until_beat := 0.0
## Share of the power it asks for the Station is getting, 0 to 1. Below 1 its
## screen browns out: dimmer the less it gets, and flickering.
var _supplied := 1.0
## The flicker's own chance, seeded by the Station's name: the same flicker
## every run, whatever else draws on the global generator.
var _flicker := RandomNumberGenerator.new()


func _ready() -> void:
	_flicker.seed = hash(station_name)
	add_child(_cradle)
	_add_yoke()
	if station_name.is_empty():
		return
	var desk := MeshInstance3D.new()
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(SCREEN_SIZE.x + 0.1, 0.04, 0.5)
	desk.mesh = desk_mesh
	desk.material_override = _material(Color(0.29, 0.34, 0.37))
	desk.position = Vector3(0, -0.08, 0)
	_cradle.add_child(desk)

	# The screen faces the cradle's -z, out from the Bore; the crew work it
	# from that side.
	_screen = StationScreen.new()
	_screen.set_station_name(station_name)
	add_child(_screen)
	_screen_material = _panel(_screen.get_texture(), SCREEN_SIZE, 0.0)

	# The Station's own light, dark until it calls for attention.
	_call_light = OmniLight3D.new()
	_call_light.light_color = hue
	_call_light.light_energy = 0.0
	_call_light.omni_range = 2.5
	_call_light.position = Vector3(0, SCREEN_SIZE.y + 0.1, -0.3)
	_cradle.add_child(_call_light)

	# Its own tone, from where it hangs, so the ring tells the ear which way.
	_call_sound = AudioStreamPlayer3D.new()
	_call_sound.stream = call_tone(call_tone_hz, call_pips)
	_call_sound.unit_size = 2.0
	_call_sound.position = SCREEN_CENTRE
	_cradle.add_child(_call_sound)
	_disengage_sound = AudioStreamPlayer3D.new()
	_disengage_sound.stream = disengage_tone()
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
	_screen_material.albedo_color = Color(dim, dim, dim)
	if _keys_material:
		_keys_material.albedo_color = Color(dim, dim, dim)
	_show_header()
	var held := CALL_LIGHT_HELD_ENERGY if _urgency > 0.0 else 0.0
	_call_light.light_energy = maxf(held, _call_light.light_energy * exp(-delta / CALL_LIGHT_FADE_S))
	if _urgency <= 0.0 or not _sounding:
		_until_beat = 0.0
		_chimed = false
		return
	if not _warns:
		if not _chimed:
			_chimed = true
			_beat()
		return
	_until_beat -= delta
	if _until_beat <= 0.0:
		_until_beat = beat_seconds(_urgency)
		_beat()


## One beat of the call: the Station's tone and a flash of its light.
func _beat() -> void:
	_call_light.light_energy = CALL_LIGHT_ENERGY
	_call_sound.pitch_scale = pitch_scale(_urgency)
	_call_sound.play()


## Call for attention, 0 (stop) to 1 (most urgent). A warning that sounds
## beats the Station's own tone and flashes its own light, faster and higher
## the more urgent; a report that sounds (`warns` false: a feature in the
## Column) chimes once. Once it no longer sounds (acknowledged), or after the
## chime, the light stays lit, steady and silent, until the call ends.
## Nothing is drawn over the view; the screen says why.
func set_call(urgency: float, sounding := true, warns := true) -> void:
	_urgency = clampf(urgency, 0.0, 1.0)
	_sounding = sounding
	_warns = warns


func is_calling() -> bool:
	return _urgency > 0.0


## The Station's autopilot has just let go: the disconnect warning sounds
## here, and AUTOPILOT OFF flashes on the screen.
func autopilot_off() -> void:
	_since_disengaged = 0.0
	if _disengage_sound:
		_disengage_sound.play()


## The autopilot's word in the screen's header strip: AUTOPILOT while engaged,
## AUTOPILOT OFF while not, blinking for DISENGAGE_FLASH_S after it let go
## (blank in the blink's off half).
static func autopilot_caption(engaged: bool, since_disengaged: float) -> String:
	if engaged:
		return "AUTOPILOT"
	if since_disengaged < DISENGAGE_FLASH_S \
			and fmod(since_disengaged, 2.0 * DISENGAGE_BLINK_S) >= DISENGAGE_BLINK_S:
		return ""
	return "AUTOPILOT OFF"


## What the autopilot's word means, for its colour (StationTheme): engaged
## and working; a caution while it flashes, having just let go; else simply
## how things are.
static func autopilot_meaning(engaged: bool, since_disengaged: float) -> StringName:
	if engaged:
		return StationTheme.ENGAGED
	return StationTheme.CAUTION if since_disengaged < DISENGAGE_FLASH_S else StationTheme.NOW


## Seconds between beats of a call this urgent.
static func beat_seconds(urgency: float) -> float:
	return lerpf(CALL_BEAT_CALM_S, CALL_BEAT_URGENT_S, clampf(urgency, 0.0, 1.0))


## Pitch scale of the call tone for a call this urgent.
static func pitch_scale(urgency: float) -> float:
	return 1.0 + CALL_PITCH_RISE * clampf(urgency, 0.0, 1.0)


## One beat of a call: `pips` short pips of a Station's tone (`tone_hz`),
## with a little of its octave so it carries, each faded in and out to avoid
## clicks.
static func call_tone(tone_hz: float, pips: int) -> AudioStreamWAV:
	var pip := int(_PIP_S * _TONE_RATE)
	var gap := int(_PIP_GAP_S * _TONE_RATE)
	var frames := pips * (pip + gap)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var in_pip := i % (pip + gap)
		var value := 0.0
		if in_pip < pip:
			var t := float(i) / _TONE_RATE
			var envelope := minf(1.0, minf(in_pip, pip - in_pip) / (0.01 * _TONE_RATE))
			value = envelope * (0.8 * sin(TAU * tone_hz * t) + 0.2 * sin(TAU * 2.0 * tone_hz * t))
		data.encode_s16(i * 2, int(value * CALL_LEVEL * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = _TONE_RATE
	wav.stereo = false
	wav.data = data
	return wav


## The disconnect warning: DISENGAGE_NOTES one after another, each a pure
## tone swelling and dying away over its whole length (a raised cosine), so
## it has no hard edge.
static func disengage_tone() -> AudioStreamWAV:
	var note := int(_DISENGAGE_NOTE_S * _TONE_RATE)
	var data := PackedByteArray()
	data.resize(DISENGAGE_NOTES.size() * note * 2)
	for n in DISENGAGE_NOTES.size():
		for i in note:
			var t := float(i) / _TONE_RATE
			var envelope := 0.5 - 0.5 * cos(TAU * float(i) / note)
			var value := envelope * sin(TAU * DISENGAGE_NOTES[n] * t)
			data.encode_s16((n * note + i) * 2, int(value * DISENGAGE_LEVEL * 32767.0))
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


## The Station's screen: its frame, where a Station puts its own instrument
## (screen().set_instrument(), or show_display() for a live picture) and its
## Caution lamps (show_lamps()). Null on an empty mount.
func screen() -> StationScreen:
	return _screen


## The Station's key list beside its screen; null until show_keys().
func key_list() -> KeyList:
	return _keys


## Text shown on the Station's screen as its status lines, all in white; see
## show_lines() for lines in the colours of what they mean.
func show_reading(text: String) -> void:
	show_lines(Array(text.split("\n")))


## The Station's status lines, on its screen under its instrument: each a
## String (white: what is happening now) or [text, meaning] with a meaning
## of StationTheme. The text shrinks as needed so every line is whole.
func show_lines(lines: Array) -> void:
	if _screen == null:
		return
	_show_header()
	_screen.show_lines(lines)


## The Station's Caution lamps in its header strip: each {label, lit}, as
## CautionLamps.of() gives them.
func show_lamps(lamps: Array[Dictionary]) -> void:
	if _screen:
		_screen.show_lamps(lamps)


## The header strip's autopilot word and the footer, as they stand now.
func _show_header() -> void:
	_screen.set_autopilot(autopilot_caption(autopilot, _since_disengaged),
			autopilot_meaning(autopilot, _since_disengaged))
	_screen.set_footer(footer)


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
## readings: its header strip (the name first), each status line and the
## footer, top to bottom; then its displays if it shows any, left to right;
## then each of a lone display's instruments, which lie over it; then the
## readings inside an instrument made of Controls
## (StationScreen.instrument_readings()) (see reading(), is_display(),
## display_index(), instrument()). An empty mount
## has no readings. The readings are where the screen's Containers laid them
## out, so they are placed only once the Station is in the tree and a frame
## has passed.
func face() -> Pointing.Face:
	var face := face_for(position, _cradle.basis)
	if _screen == null:
		return face
	for rect in _screen.text_rects():
		face.readings.append(_on_face(rect))
	for d in _screen.picture_count():
		face.readings.append(_on_face(_screen.picture_rect(d)))
	if _screen.picture_count() == 1:
		var picture := _screen.picture_rect(0)
		for share in _instrument_shares:
			face.readings.append(_on_face(Rect2(picture.position + share.position * picture.size,
					share.size * picture.size)))
	for inside in _screen.instrument_readings():
		face.readings.append(_on_face(inside.rect))
	return face


## A rectangle of the screen's own pixels (StationScreen: x across, y down
## from the top left) in face coordinates (metres: x the crew's right, y up,
## origin at the middle).
static func _on_face(pixels: Rect2) -> Rect2:
	var metres := SCREEN_SIZE / Vector2(StationScreen.SIZE)
	return Rect2(pixels.position.x * metres.x - SCREEN_SIZE.x / 2.0,
			SCREEN_SIZE.y / 2.0 - pixels.end.y * metres.y, pixels.size.x * metres.x, pixels.size.y * metres.y)


## What the reading at this index of face().readings shows: its text (the
## header strip's name and autopilot word, a status line, the footer), or ""
## for a display.
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
	return d if _screen and d >= 0 and d < _screen.picture_count() else -1


## The name of the instrument reading at this index of face().readings: a
## display's instrument (as show_display() was given it) or a reading inside
## an instrument made of Controls (as its readings() names it), or &"" for
## anything else.
func instrument(index: int) -> StringName:
	if _screen == null:
		return &""
	var i := index - _lines().size() - _screen.picture_count()
	if i >= 0 and i < _instrument_names.size():
		return _instrument_names[i]
	var inside := _screen.instrument_readings()
	i -= _instrument_names.size()
	return inside[i].name if i >= 0 and i < inside.size() else &""


## The screen's text readings, the header strip first; none on an empty mount.
func _lines() -> PackedStringArray:
	return _screen.texts() if _screen else PackedStringArray()


## The screen of a Station pivoting at pivot with its cradle at cradle, as a
## face with no readings: facing the working pose, the crew's right as x.
static func face_for(pivot: Vector3, cradle: Basis) -> Pointing.Face:
	var screen := Pointing.Face.new()
	# The screen box's front, on the Head side where its text faces.
	var front := SCREEN_CENTRE + Vector3(0, 0, -0.01)
	screen.transform = Transform3D(cradle * Basis(Vector3.UP, PI), pivot + cradle * front)
	screen.bounds = Rect2(-SCREEN_SIZE / 2.0, SCREEN_SIZE)
	return screen


## Show a live picture (e.g. a SubViewport's texture) as the Station's
## instrument, in the body of its screen's frame, keeping its shape.
## instruments names the picture's instruments, each a reading of its own:
## {name: its place as shares of the picture, 0 to 1 across from the left and
## down from the top}.
func show_display(texture: Texture2D, instruments: Dictionary = {}) -> void:
	if _screen == null:
		return
	var textures: Array[Texture2D] = [texture]
	show_displays(textures)
	for name: StringName in instruments:
		_instrument_names.append(name)
		_instrument_shares.append(instruments[name])


## Show live pictures side by side as the Station's instrument, the first on
## the crew's left, sharing the body of its screen's frame equally; each
## keeps its shape and is its own reading. No instruments.
func show_displays(textures: Array[Texture2D]) -> void:
	if _screen == null:
		return
	_instrument_names = []
	_instrument_shares = []
	_screen.show_pictures(textures)


## Show the Station's keys on a panel beside its screen, on the crew's right
## as they work it: each binding's key prompts, then what it does. Pass
## KeyMap.bindings_at(<this Station>), so the panel is the key map.
func show_keys(bindings: Array[Dictionary]) -> void:
	if _screen == null:
		return
	if _keys == null:
		_keys = KeyList.new()
		add_child(_keys)
		# The screen faces the cradle's -z, so the crew's right is -x.
		_keys_material = _panel(_keys.get_texture(), Vector2(KEYS_WIDTH, SCREEN_SIZE.y),
				-(SCREEN_SIZE.x / 2.0 + KEYS_GAP + KEYS_WIDTH / 2.0))
	_keys.show_keys(bindings)


## A panel in the cradle showing a viewport's texture, lit by itself, in a
## dark casing: `panel_size` in metres, its middle `x` along the cradle's x
## from the screen's. Returns its material, which dims it.
func _panel(texture: Texture2D, panel_size: Vector2, x: float) -> StandardMaterial3D:
	var casing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(panel_size.x + 2.0 * CASING, panel_size.y + 2.0 * CASING, 0.02)
	casing.mesh = box
	casing.material_override = _material(CASING_COLOUR)
	casing.position = SCREEN_CENTRE + Vector3(x, 0, 0)
	_cradle.add_child(casing)
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = panel_size
	face.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	face.material_override = material
	# Turned to face the crew, on the cradle's -z side.
	face.position = SCREEN_CENTRE + Vector3(x, 0, -0.012)
	face.rotation = Vector3(0, PI, 0)
	_cradle.add_child(face)
	return material


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

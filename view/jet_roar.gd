## The Glide heard in the Habitat (ticket #127): the roar of melt forced
## through the Bore as a jet, building as the jet spins up, sustained at full
## thrust, dying away to the silence of the idle after it. Reads only
## DiveSimulation.glide_thrust(). A generated placeholder, as SlipSound is.
##
## A jet's noise is broadband, loudest at a peak whose frequency rises with
## the flow's speed (the Strouhal relation: peak about 0.2 times speed over
## the jet's width), and its power rises steeply with speed (Lighthill: as
## its eighth power). So the spin-up is heard as a roar rising in pitch and
## loudness at once, and the spin-down as the same falling: unlike the
## Crawl's juddering grind (SlipSound), which is chopped and low. Under it a
## low rumble of the hull carrying the thrust, and a faint whine of the
## Head's power rising with the load, as a motor's does.
class_name JetRoar
extends AudioStreamPlayer

const MIX_RATE := 22050.0
const SILENT_DB := -60.0
const LOUDEST_DB := -4.0
## The roar's peak frequency, hertz, as the jet starts and at full thrust.
const PEAK_SLOW_HZ := 180.0
const PEAK_FULL_HZ := 900.0
## The whine of the Head's power, hertz, idle and at full load.
const WHINE_SLOW_HZ := 140.0
const WHINE_FULL_HZ := 520.0

var sim: DiveSimulation

## The noise generator: the sound's own, so it never draws on the global
## generator the picture's chance comes from.
var _rng := RandomNumberGenerator.new()
## Filter states: the roar's band (two one-pole stages), the rumble's low pass;
## the whine's phase.
var _band_low := 0.0
var _band_high := 0.0
var _rumble := 0.0
var _whine_phase := 0.0


func _ready() -> void:
	# With no sound device (headless: the tests, a server) nothing is played:
	# a playing generator freed there can crash Godot (see SlipSound).
	if AudioServer.get_driver_name() == "Dummy":
		return
	_rng.seed = 127
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.1
	stream = generator
	volume_db = SILENT_DB
	play()


func _process(_delta: float) -> void:
	if sim and playing:
		_feed(sim.glide_thrust() if sim.gliding() else 0.0)


## How loud the roar plays at this thrust, dB: silent with no jet, rising
## steeply as the jet builds (a jet's power grows with a high power of its
## speed, here held to a curve the ear can follow).
static func loudness_db(thrust: float) -> float:
	if thrust <= 0.0:
		return SILENT_DB
	return lerpf(SILENT_DB, LOUDEST_DB, pow(clampf(thrust, 0.0, 1.0), 0.35))


## The roar's peak frequency at this thrust, hertz: rising with the jet's
## speed, as the Strouhal relation has it.
static func peak_hz(thrust: float) -> float:
	return lerpf(PEAK_SLOW_HZ, PEAK_FULL_HZ, clampf(thrust, 0.0, 1.0))


func _feed(thrust: float) -> void:
	var playback := get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	volume_db = loudness_db(thrust)
	# One-pole coefficients for the roar's band round its peak, and the rumble.
	var peak := peak_hz(thrust)
	var high_pass := exp(-TAU * peak * 0.5 / MIX_RATE)
	var low_pass := 1.0 - exp(-TAU * peak * 2.0 / MIX_RATE)
	var rumble_pass := 1.0 - exp(-TAU * 70.0 / MIX_RATE)
	var whine_hz := lerpf(WHINE_SLOW_HZ, WHINE_FULL_HZ, thrust)
	for i in playback.get_frames_available():
		var white := _rng.randf_range(-1.0, 1.0)
		# Band: low-pass above the peak, then take away what is below it.
		_band_low = lerpf(_band_low, white, low_pass)
		_band_high = high_pass * _band_high + (1.0 - high_pass) * _band_low
		var roar := (_band_low - _band_high) * 2.4
		_rumble = lerpf(_rumble, white, rumble_pass)
		_whine_phase = fmod(_whine_phase + whine_hz / MIX_RATE, 1.0)
		var whine := sin(_whine_phase * TAU) * 0.05 * thrust
		var level := (roar + _rumble * 3.0 * thrust + whine) if thrust > 0.0 else 0.0
		playback.push_frame(Vector2(level, level))

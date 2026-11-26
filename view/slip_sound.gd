## The grinding of the grip waves slipping on the tunnel wall, heard in the
## Habitat: low-passed noise chopped by a juddering envelope, louder and faster
## with more slip, silent while gripping. Reads only DiveSimulation.slip().
## A placeholder sound until the Habitat has a real one.
class_name SlipSound
extends AudioStreamPlayer

const MIX_RATE := 22050.0
const SILENT_DB := -60.0
const LOUDEST_DB := -6.0

var sim: DiveSimulation

## Low-passed noise state and a slow judder phase.
var _grind := 0.0
var _judder_phase := 0.0


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.1
	stream = generator
	volume_db = SILENT_DB
	play()


func _process(_delta: float) -> void:
	if sim:
		_feed(sim.slip())


func _feed(slip: float) -> void:
	var playback := get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	volume_db = lerpf(SILENT_DB, LOUDEST_DB, sqrt(slip))
	var judder_hz := lerpf(6.0, 18.0, slip)
	for i in playback.get_frames_available():
		_grind = lerpf(_grind, randf_range(-1.0, 1.0), 0.15)
		_judder_phase = fmod(_judder_phase + judder_hz / MIX_RATE, 1.0)
		var envelope := 0.4 + 0.6 * absf(sin(_judder_phase * PI))
		var level := _grind * envelope * 2.0 if slip > 0.0 else 0.0
		playback.push_frame(Vector2(level, level))

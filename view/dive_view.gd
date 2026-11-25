## Bare view of a dive: reads the simulation and sends it commands.
## Holds no game state of its own. The scene that owns the simulation
## advances it and hands it over with attach().
##
## Slip is shown here as an overlay on the Habitat: a red SLIP bar and
## label that shake with slip, and a placeholder grinding noise whose
## loudness follows DiveSimulation.slip().
class_name DiveView
extends Control

const POWER_STEP := 0.1
## Placeholder slip sound: sample rate and loudness range of the grinding noise.
const SLIP_MIX_RATE := 22050.0
const SLIP_SILENT_DB := -60.0
const SLIP_LOUDEST_DB := -6.0
## How far the slip readout shakes at full slip, in pixels.
const SLIP_SHAKE_PX := 6.0

var _sim: DiveSimulation
var _slip_player: AudioStreamPlayer
## Low-passed noise state and a slow judder phase for the grinding sound.
var _grind := 0.0
var _judder_phase := 0.0

@onready var _power_slider: HSlider = %PowerSlider
@onready var _power_label: Label = %PowerLabel
@onready var _depth_label: Label = %DepthLabel
@onready var _medium_label: Label = %MediumLabel
@onready var _speed_label: Label = %SpeedLabel
@onready var _slip_label: Label = %SlipLabel
@onready var _slip_bar: ProgressBar = %SlipBar


func _ready() -> void:
	_power_slider.value_changed.connect(_on_power_changed)


## Start reading and commanding this simulation.
func attach(sim: DiveSimulation) -> void:
	_sim = sim
	_on_power_changed(_power_slider.value)
	_start_slip_sound()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_up"):
		_power_slider.value += POWER_STEP
	elif event.is_action_pressed(&"ui_down"):
		_power_slider.value -= POWER_STEP


func _physics_process(_delta: float) -> void:
	if not _sim:
		return
	_depth_label.text = "Depth: %.1f m" % _sim.depth()
	_medium_label.text = "Medium: %s" % String(_sim.medium().name).capitalize()
	_speed_label.text = "Speed: %.2f m/s" % _sim.speed()
	_show_slip(_sim.slip())


func _process(_delta: float) -> void:
	if _sim:
		_feed_slip_sound(_sim.slip())


func _on_power_changed(value: float) -> void:
	if _sim:
		_sim.set_power(value)
	_power_label.text = "Power: %d%%" % roundi(value * 100.0)


func _show_slip(slip: float) -> void:
	_slip_bar.value = slip
	var slipping := slip > 0.0
	_slip_label.text = "SLIP %d%%" % roundi(slip * 100.0) if slipping else "Gripping"
	_slip_label.modulate = Color(1.0, 0.25, 0.2) if slipping else Color(0.6, 0.9, 0.6)
	var shake := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SLIP_SHAKE_PX * slip
	_slip_label.position.x = shake.x
	_slip_bar.modulate = Color(1.0, 1.0 - slip, 1.0 - slip)


# --- Placeholder slip sound -----------------------------------------------

func _start_slip_sound() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SLIP_MIX_RATE
	stream.buffer_length = 0.1
	_slip_player = AudioStreamPlayer.new()
	_slip_player.stream = stream
	_slip_player.volume_db = SLIP_SILENT_DB
	add_child(_slip_player)
	_slip_player.play()


## Grinding: low-passed noise chopped by a juddering envelope, louder and
## faster with more slip. Silent when gripping.
func _feed_slip_sound(slip: float) -> void:
	var playback := _slip_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	_slip_player.volume_db = lerpf(SLIP_SILENT_DB, SLIP_LOUDEST_DB, sqrt(slip))
	var judder_hz := lerpf(6.0, 18.0, slip)
	for i in playback.get_frames_available():
		_grind = lerpf(_grind, randf_range(-1.0, 1.0), 0.15)
		_judder_phase = fmod(_judder_phase + judder_hz / SLIP_MIX_RATE, 1.0)
		var envelope := 0.4 + 0.6 * absf(sin(_judder_phase * PI))
		var sample := _grind * envelope * 2.0 if slip > 0.0 else 0.0
		playback.push_frame(Vector2(sample, sample))

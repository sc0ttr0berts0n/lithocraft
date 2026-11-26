## Developer debug overlay of a dive, drawn over the Habitat: depth, Medium,
## speed, a SLIP bar, Drive power, a ColumnStrip on the right edge with a metre
## ruler, and the SurveyPanel and TunnelPanel. Hidden by default and toggled
## with F3, or from the numpad debug menu (habitat.gd): the crew learn all of this from the vessel itself
## (story 52), through the Station screens, the Bore, the shake and the sound.
## Reads the simulation only; holds no game state and sends no commands. The
## scene that owns the simulation hands it over with attach().
class_name DiveView
extends Control

## How far the slip readout shakes at full slip, in pixels.
const SLIP_SHAKE_PX := 6.0

var _sim: DiveSimulation

@onready var _power_slider: HSlider = %PowerSlider
@onready var _power_label: Label = %PowerLabel
@onready var _depth_label: Label = %DepthLabel
@onready var _medium_label: Label = %MediumLabel
@onready var _speed_label: Label = %SpeedLabel
@onready var _slip_label: Label = %SlipLabel
@onready var _slip_bar: ProgressBar = %SlipBar
@onready var _column_strip: ColumnStrip = %ColumnStrip
@onready var _survey_panel: SurveyPanel = %SurveyPanel
@onready var _tunnel_panel: TunnelPanel = %TunnelPanel


func _ready() -> void:
	_power_slider.editable = false


## Start reading this simulation.
func attach(sim: DiveSimulation) -> void:
	_sim = sim
	_column_strip.sim = sim
	_survey_panel.sim = sim
	_tunnel_panel.sim = sim


func _physics_process(_delta: float) -> void:
	if not _sim or not is_visible_in_tree():
		return
	_depth_label.text = "Depth: %.1f m" % _sim.depth()
	_medium_label.text = "Medium: %s" % String(_sim.medium().name).capitalize()
	_speed_label.text = "Speed: %.2f m/s" % _sim.speed()
	_power_slider.value = _sim.power()
	_power_label.text = "Power: %d%%" % roundi(_sim.power() * 100.0)
	_show_slip(_sim.slip())


func _show_slip(slip: float) -> void:
	_slip_bar.value = slip
	var slipping := slip > 0.0
	_slip_label.text = "SLIP %d%%" % roundi(slip * 100.0) if slipping else "Gripping"
	_slip_label.modulate = Color(1.0, 0.25, 0.2) if slipping else Color(0.6, 0.9, 0.6)
	var shake := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SLIP_SHAKE_PX * slip
	_slip_label.position.x = shake.x
	_slip_bar.modulate = Color(1.0, 1.0 - slip, 1.0 - slip)

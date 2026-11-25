## Bare view of a dive: reads the simulation and sends it commands.
## Holds no game state of its own. The scene that owns the simulation
## advances it and hands it over with attach().
class_name DiveView
extends Control

const POWER_STEP := 0.1

var _sim: DiveSimulation

@onready var _power_slider: HSlider = %PowerSlider
@onready var _power_label: Label = %PowerLabel
@onready var _depth_label: Label = %DepthLabel


func _ready() -> void:
	_power_slider.value_changed.connect(_on_power_changed)


## Start reading and commanding this simulation.
func attach(sim: DiveSimulation) -> void:
	_sim = sim
	_on_power_changed(_power_slider.value)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_up"):
		_power_slider.value += POWER_STEP
	elif event.is_action_pressed(&"ui_down"):
		_power_slider.value -= POWER_STEP


func _physics_process(_delta: float) -> void:
	if _sim:
		_depth_label.text = "Depth: %.1f m" % _sim.depth()


func _on_power_changed(value: float) -> void:
	if _sim:
		_sim.set_power(value)
	_power_label.text = "Power: %d%%" % roundi(value * 100.0)

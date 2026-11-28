## The Glide in the Bore: where a Glide melted the Column, the Bore carries a
## river of incandescent rock melt instead, and its light floods the Habitat
## through the glass (ticket #127).
##
## The melt is drawn on the Column's own tube: the Column strip leaves the
## bands with no Column (DiveSimulation.column_absent()) clear, and the tube's
## shader paints melt wherever the strip is clear, so the melt replaces the
## Column exactly where the simulation says there is none. Everything here
## follows the simulation's state and dive_time(): how hot the melt is (the
## jet's thrust while a Glide runs, cooling after it), how fast it streams,
## and which of the Bore's lights are lit by it, so a screenshot repeats.
##
## What it is: silicate melt under pressure, heated by the Head's plasma, at
## about 1750 K at full thrust (hotter than lava, which erupts at 1300 to
## 1450 K), streaming aft through the Bore. Its colour is a hot body's at that
## temperature; what it radiates grows as the fourth power of it
## (Stefan-Boltzmann), so the cooling slug after a Glide dims far faster than
## it reddens. The face is many times the Bore's area, so the melt runs aft
## many times faster than the vessel moves: too fast for the eye to follow,
## seen as streaks drawn out along the Bore.
class_name BoreMelt
extends Node3D

## The melt's temperature, kelvin: at full thrust, as the jet starts or dies
## (thrust 0 with the Glide still running), and the crust the halted slug
## cools toward after it.
const FULL_K := 1750.0
const SLOW_K := 1400.0
const CRUST_K := 850.0
## Seconds for the halted melt's surface to lose about two thirds of its heat
## above the crust's: a skin chills fast on a melt that has stopped moving.
const COOL_S := 6.0
## How bright the melt is drawn at FULL_K, as the screen's white is 1: above 1
## so it blooms (the Habitat's glow is on while any melt is lit).
const FULL_BRIGHT := 2.6
## The Bore's melt lights: how many along the Bore, their reach (metres) and
## their energy at FULL_K. Their energy falls as the fourth power of the
## temperature, as the melt's radiance does.
const LIGHTS := 4
const LIGHT_RANGE_M := 7.5
const LIGHT_ENERGY := 3.2
## How strongly the melt tints the room's ambient light at FULL_K.
const AMBIENT_SHARE := 0.55
## The melt's two patterns: slow lumps as the jet starts or dies (metres long
## along the Bore, and how many of their lengths they move a second), and the
## fast streaks of the jet at full thrust, drawn long because they move too
## fast to see.
const LUMP_M := 0.45
const LUMP_RATE := 1.1
const STREAK_M := 4.5
const STREAK_RATE := 7.0
## Where the patterns' travel wraps round, in their own lengths, to keep the
## shader's numbers small: a jump in the pattern once every ten minutes or so.
const PHASE_WRAP := 4096.0

## A hot body's colour by temperature (kelvin -> colour at full brightness),
## between which colour() blends.
const _HOT_BODY := [
	[800.0, Color(1.0, 0.12, 0.0)],
	[1000.0, Color(1.0, 0.2, 0.0)],
	[1200.0, Color(1.0, 0.3, 0.02)],
	[1500.0, Color(1.0, 0.42, 0.05)],
	[1750.0, Color(1.0, 0.5, 0.12)],
	[2000.0, Color(1.0, 0.58, 0.22)],
	[2500.0, Color(1.0, 0.68, 0.38)],
]

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D column : source_color, filter_linear;
// The melt's colour at its hottest and in its cooler filaments, brightness
// folded in (above 1 blooms).
uniform vec3 hot;
uniform vec3 cool;
// The crust's colour, and how much of the surface it covers (0 while the jet
// runs, growing as the halted melt cools).
uniform vec3 crust;
uniform float crusted;
// The lumps' and the streaks' length along the Bore (metres) and how far
// each has moved (in its own lengths); how much the streaks show (the
// jet's thrust).
uniform float lump_m;
uniform float lump_phase;
uniform float streak_m;
uniform float streak_phase;
uniform float streaking;

varying vec3 at;

void vertex() {
	at = VERTEX;
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	return 0.55 * noise(p) + 0.3 * noise(p * 2.03 + 7.1) + 0.15 * noise(p * 4.1 + 3.7);
}

void fragment() {
	vec4 rock = texture(column, UV);
	if (rock.a > 0.5) {
		ALBEDO = rock.rgb;
	} else {
		// Round the Bore as a circle, so the pattern closes on itself.
		vec2 round_at = normalize(at.xy) * 1.6;
		float lumps = fbm(vec3(round_at * 2.2, at.z / lump_m - lump_phase));
		float streaks = fbm(vec3(round_at * 4.5, at.z / streak_m - streak_phase));
		float n = mix(lumps, streaks, streaking);
		vec3 melt = mix(cool, hot, smoothstep(0.38, 0.74, n));
		// The crust: dark plates, still glowing along the cracks between.
		float plates = noise(vec3(round_at * 3.0, at.z * 2.2));
		float crack = 1.0 - smoothstep(0.0, 0.07, abs(plates - 0.5));
		float plate = smoothstep(0.2, 0.9, crusted);
		ALBEDO = mix(melt, mix(crust, melt * 1.3, crack), plate);
	}
}
"""

var sim: DiveSimulation
## How far behind the Head each of the Bore's melt lights sits, metres, set
## by the Habitat from where it places them (Habitat.behind_head_at()).
var light_behind_head: Array[float] = []

var _material: ShaderMaterial
var _environment: Environment
var _ambient_colour: Color
var _lights: Array[OmniLight3D] = []
## Whether a Glide ran at the last step, and the dive time the last one
## ended at (INF while one runs, -INF before any): the halted melt cools from
## then.
var _was_gliding := false
var _ended_at := -INF


## The material for the Column's tube: the Column strip's texture where there
## is Column, the melt where the strip is clear.
static func material(column_texture: Texture2D) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter(&"column", column_texture)
	m.set_shader_parameter(&"lump_m", LUMP_M)
	m.set_shader_parameter(&"streak_m", STREAK_M)
	return m


## Sets the melt up on the Column tube's material, the room's environment
## (whose ambient light and glow it tints) and lights at these places along
## the Bore (Habitat z), each `behind_head` metres behind the Head.
func attach(on: ShaderMaterial, environment: Environment, light_z: Array[float],
		behind_head: Array[float]) -> void:
	_material = on
	_environment = environment
	_ambient_colour = environment.ambient_light_color
	light_behind_head = behind_head
	for z in light_z:
		var light := OmniLight3D.new()
		light.omni_range = LIGHT_RANGE_M
		light.light_energy = 0.0
		light.visible = false
		light.position = Vector3(0, 0, z)
		add_child(light)
		_lights.append(light)
	step()


## The melt's temperature now, kelvin: with the jet's thrust while a Glide
## runs; cooling toward the crust's after it; 0 before any Glide.
func temperature() -> float:
	if sim.gliding():
		return lerpf(SLOW_K, FULL_K, sim.glide_thrust())
	if _ended_at == -INF:
		return 0.0
	return CRUST_K + (SLOW_K - CRUST_K) * exp(-(sim.dive_time() - _ended_at) / COOL_S)


## How brightly the melt radiates now, 1 at FULL_K: as the fourth power of
## its temperature.
func radiance() -> float:
	return pow(temperature() / FULL_K, 4.0)


## Whether the Bore shows melt this far behind the Head: exactly where the
## simulation has no Column.
func melt_at(behind_head: float) -> bool:
	return sim.column_absent(behind_head)


## The energy of each of the Bore's melt lights now (0 where there is Column
## by it), in the order the Habitat placed them.
func light_energies() -> Array[float]:
	var energies: Array[float] = []
	for light in _lights:
		energies.append(light.light_energy if light.visible else 0.0)
	return energies


## A hot body's colour at this temperature, full brightness.
static func colour(kelvin: float) -> Color:
	if kelvin <= _HOT_BODY[0][0]:
		return _HOT_BODY[0][1]
	for i in range(1, _HOT_BODY.size()):
		if kelvin <= _HOT_BODY[i][0]:
			var share: float = (kelvin - _HOT_BODY[i - 1][0]) / (_HOT_BODY[i][0] - _HOT_BODY[i - 1][0])
			return (_HOT_BODY[i - 1][1] as Color).lerp(_HOT_BODY[i][1], share)
	return _HOT_BODY.back()[1]


## The shader's settings, the lights and the room's ambient light and glow,
## from the simulation now. Called each step by the Habitat after advance().
func step() -> void:
	if sim == null or _material == null:
		return
	var now := sim.dive_time()
	if sim.gliding():
		_was_gliding = true
	elif _was_gliding:
		_was_gliding = false
		_ended_at = now
	var kelvin := temperature()
	var bright := radiance()
	var thrust := sim.glide_thrust()
	# The melt stops moving when the Glide ends.
	var flowing_until := now if sim.gliding() else _ended_at
	var hue := colour(kelvin)
	_material.set_shader_parameter(&"hot", _bright(colour(kelvin + 250.0), bright * FULL_BRIGHT))
	_material.set_shader_parameter(&"cool", _bright(colour(kelvin - 300.0), bright * FULL_BRIGHT * 0.3))
	_material.set_shader_parameter(&"crust", Vector3(0.07, 0.035, 0.03))
	_material.set_shader_parameter(&"crusted", 0.0 if sim.gliding() else 1.0 - (kelvin - CRUST_K) / (SLOW_K - CRUST_K))
	_material.set_shader_parameter(&"lump_phase", fmod(maxf(flowing_until, 0.0) * LUMP_RATE, PHASE_WRAP))
	_material.set_shader_parameter(&"streak_phase", fmod(maxf(flowing_until, 0.0) * STREAK_RATE, PHASE_WRAP))
	_material.set_shader_parameter(&"streaking", thrust if sim.gliding() else 0.0)
	var any_lit := false
	for i in _lights.size():
		var lit := bright > 0.0 and melt_at(light_behind_head[i])
		_lights[i].visible = lit
		_lights[i].light_color = hue
		_lights[i].light_energy = LIGHT_ENERGY * bright if lit else 0.0
		any_lit = any_lit or lit
	var share := AMBIENT_SHARE * bright if any_lit else 0.0
	_environment.ambient_light_color = _ambient_colour.lerp(hue, clampf(share, 0.0, 1.0))
	_environment.glow_enabled = any_lit


static func _bright(c: Color, by: float) -> Vector3:
	return Vector3(c.r, c.g, c.b) * by

## Hull damage you can feel, as in Elite Dangerous near a star: while heat is
## wearing the hull, sparks spit from the outer wall and the view shakes; as it
## creeps the hull groans from points round the ring, louder and more often with
## wear and stress, and rising while the crew holds the self-destruct command
## (HullGroans decides when). Everything is in the room or in
## sound: nothing is drawn over the crew's view (story 52). Reads only the
## simulation. The Habitat calls step() each physics frame after advance() and
## adds shake_metres() to the crew's shake.
##
## The whole hull wears, but only the stretch of wall near the crew is shown
## and heard: the emitters and voices are all placed within TUNED_IN_M of wall
## about where the crew are, so the feel is the same however long the Habitat
## is and wherever in it they stand, and costs the same.
class_name HullFeel
extends Node3D

## A groan started from this point on the outer wall (Habitat frame).
signal groaned(at: Vector3)

## The length of outer wall, along the Bore, that the sparks and groans are
## spread over: the Habitat's whole length when the feel was tuned (the second
## play test), and the stretch near the crew now it is longer.
const TUNED_IN_M := 2.4

## Sparks and shake are at their fullest once the hull's creep would fail it
## within this many seconds. Tuned for feel.
const FULLEST_WITHIN_S := 120.0
## Share of the full sparks and shake at the first sign of damage, so any
## damage at all is felt.
const FIRST_SIGN := 0.25
## How far the view shakes while the hull takes damage, metres, at the first
## sign and at the fullest.
const SHAKE_LEAST_M := 0.003
const SHAKE_MOST_M := 0.014
## Spark emitters round the outer wall; each jumps to a fresh spot every so
## often, so the sparks come from all round the ring.
const SPARK_EMITTERS := 4
const SPARK_MOVE_S := Vector2(0.4, 1.6)
const SPARK_COLOUR := Color(1.0, 0.72, 0.3)
## Groans heard at once at most, and their loudness range in decibels.
const GROAN_VOICES := 4
const GROAN_QUIET_DB := -18.0
const GROAN_LOUD_DB := 6.0
## Distinct generated groans to draw from.
const GROAN_VARIANTS := 5
const MIX_RATE := 22050

var sim: DiveSimulation
## The room's outer wall (the hull side) and its length, set before _ready.
var ring_radius := 3.3
var length := TUNED_IN_M

var _groans := HullGroans.new()
var _sparks: Array[CPUParticles3D] = []
var _flashes: Array[OmniLight3D] = []
var _spark_move_in: Array[float] = []
var _voices: Array[AudioStreamPlayer3D] = []
var _next_voice := 0
var _groan_streams: Array[AudioStreamWAV] = []
var _shake := 0.0
## Where the crew are along the Bore (Habitat frame), as of the last step.
var _crew_z := 0.0


func _ready() -> void:
	for i in GROAN_VARIANTS:
		_groan_streams.append(_make_groan(i))
	for i in GROAN_VOICES:
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size = 4.0
		voice.max_db = GROAN_LOUD_DB
		add_child(voice)
		_voices.append(voice)
	for i in SPARK_EMITTERS:
		var sparks := _make_sparks()
		add_child(sparks)
		_sparks.append(sparks)
		var flash := OmniLight3D.new()
		flash.light_color = SPARK_COLOUR
		flash.omni_range = 1.5
		flash.light_energy = 0.0
		add_child(flash)
		_flashes.append(flash)
		_spark_move_in.append(0.0)


## One physics frame: sparks and shake while the hull is taking damage, groans
## as it creeps. `felt` is the felt acceleration in the Habitat frame, which
## the sparks fall along; `crew_z` is where the crew are along the Bore
## (Habitat frame), which the sparks and groans keep near.
func step(delta: float, felt: Vector3, crew_z := 0.0) -> void:
	_crew_z = crew_z
	var damaging := sim.hull_taking_damage()
	var severity := how_severe(sim.hull_creep_rate(), sim.hull_integrity()) if damaging else 0.0
	_shake = lerpf(SHAKE_LEAST_M, SHAKE_MOST_M, severity) if damaging else 0.0
	# More of the wall sparks the faster the hull wears: one emitter at the
	# first sign, all of them at the fullest.
	var sparking := ceili(severity * _sparks.size())
	for i in _sparks.size():
		_spark(i, i < sparking, severity, felt, delta)
	for groan in _groans.step(delta, damaging, sim.vessel_wear(), sim.hull_stress(),
			sim.self_destruct_hold()):
		_groan(groan.angle, groan.loudness)


## The stretch of outer wall the sparks and groans come from now, along the
## Bore (Habitat frame): x where it starts, y where it ends. TUNED_IN_M long
## about the crew, pushed back inside the room at either end; the whole room
## if that is shorter.
func near_crew() -> Vector2:
	var half := minf(length, TUNED_IN_M) / 2.0
	var middle := clampf(_crew_z, -length / 2.0 + half, length / 2.0 - half)
	return Vector2(middle - half, middle + half)


## Where each emitter that is spitting sparks now sits on the outer wall
## (Habitat frame).
func spark_spots() -> Array[Vector3]:
	var spots: Array[Vector3] = []
	for sparks in _sparks:
		if sparks.emitting:
			spots.append(sparks.position)
	return spots


## How far the view should shake this frame, metres; 0 while no damage.
func shake_metres() -> float:
	return _shake


## How severe the damage feels, FIRST_SIGN at any creep to 1 at the fullest:
## by how soon the hull, at `integrity` (the simulation's hull_integrity()),
## would fail at `creep_rate` (its hull_creep_rate()), fullest within
## FULLEST_WITHIN_S.
static func how_severe(creep_rate: float, integrity: float) -> float:
	if creep_rate <= 0.0:
		return 0.0
	var seconds_left := integrity / creep_rate
	return lerpf(FIRST_SIGN, 1.0, clampf(FULLEST_WITHIN_S / seconds_left, 0.0, 1.0))


## A point on the outer wall at `angle` round the ring and `z` along it.
func _on_wall(angle: float, z: float) -> Vector3:
	return Vector3(cos(angle) * ring_radius, sin(angle) * ring_radius, z)


func _spark(i: int, on: bool, severity: float, felt: Vector3, delta: float) -> void:
	var sparks := _sparks[i]
	var flash := _flashes[i]
	sparks.emitting = on
	if not on:
		flash.light_energy = 0.0
		return
	_spark_move_in[i] -= delta
	if _spark_move_in[i] <= 0.0:
		_spark_move_in[i] = randf_range(SPARK_MOVE_S.x, SPARK_MOVE_S.y) / (0.5 + severity)
		var angle := randf() * TAU
		# Kept a little in from the ends of the stretch, as it was from the
		# end caps of the room it was tuned in.
		var near := near_crew()
		var inset := (near.y - near.x) / 12.0
		sparks.position = _on_wall(angle, randf_range(near.x + inset, near.y - inset))
		sparks.direction = Vector3(-cos(angle), -sin(angle), 0.0)
		flash.position = sparks.position * 0.95
	sparks.gravity = felt
	flash.light_energy = randf_range(0.2, 1.4) * severity


func _groan(angle: float, loudness: float) -> void:
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	var near := near_crew()
	voice.position = _on_wall(angle, randf_range(near.x, near.y))
	voice.stream = _groan_streams[randi() % _groan_streams.size()]
	voice.volume_db = lerpf(GROAN_QUIET_DB, GROAN_LOUD_DB, loudness)
	voice.pitch_scale = randf_range(0.8, 1.15)
	voice.play()
	groaned.emit(voice.position)


func _make_sparks() -> CPUParticles3D:
	var sparks := CPUParticles3D.new()
	sparks.emitting = false
	sparks.amount = 72
	sparks.lifetime = 0.6
	sparks.explosiveness = 0.2
	sparks.randomness = 0.6
	sparks.spread = 50.0
	sparks.initial_velocity_min = 1.5
	sparks.initial_velocity_max = 4.0
	sparks.damping_min = 0.5
	sparks.damping_max = 1.5
	sparks.scale_amount_min = 0.5
	sparks.scale_amount_max = 1.2
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 0.85))
	fade.add_point(0.4, Color(1.0, 0.7, 0.2))
	fade.set_color(fade.get_point_count() - 1, Color(1.0, 0.3, 0.05, 0.0))
	sparks.color_ramp = fade
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.04, 0.04)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	sparks.mesh = mesh
	return sparks


## A generated groan: a low, rough tone sliding in pitch, like metal giving
## under load, swelling and dying away over a couple of seconds. `variant`
## seeds its pitch, length and roughness. Placeholder until a recorded one.
func _make_groan(variant: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1009 + variant
	var seconds := rng.randf_range(1.4, 2.6)
	var base_hz := rng.randf_range(38.0, 70.0)
	var slide := rng.randf_range(-0.35, 0.25)
	var creak_hz := rng.randf_range(9.0, 22.0)
	var frames := int(seconds * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase := 0.0
	var creak_phase := 0.0
	var rough := 0.0
	for n in frames:
		var t := float(n) / MIX_RATE
		var along := t / seconds
		var hz := base_hz * (1.0 + slide * along + 0.04 * sin(TAU * 0.7 * t))
		phase = fmod(phase + hz / MIX_RATE, 1.0)
		creak_phase = fmod(creak_phase + creak_hz * (1.0 + 0.3 * along) / MIX_RATE, 1.0)
		rough = lerpf(rough, rng.randf_range(-1.0, 1.0), 0.08)
		var tone := sin(TAU * phase) + 0.5 * sin(2.0 * TAU * phase) + 0.3 * sin(3.0 * TAU * phase + 0.4)
		var creak := 0.55 + 0.45 * pow(absf(sin(PI * creak_phase)), 6.0)
		var envelope := minf(1.0, t / 0.18) * pow(1.0 - along, 1.5)
		var level := clampf((tone * 0.45 + rough * 0.5) * creak * envelope, -1.0, 1.0)
		data.encode_s16(n * 2, int(level * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream

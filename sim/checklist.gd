## A Scenario's progress through one dive: which goals of its Orders are
## achieved, which Checklist steps are done, missed or still to do, and surface
## control's messages on their way down the link. Owned by DiveSimulation,
## which tends it after every step; see docs/conventions/scenarios-and-checklist.md.
##
## Unlike the other subsystems it is handed the simulation itself on each
## tend(), because a Scenario's conditions read the simulation's public
## interface; it holds no reference to it between calls.
class_name Checklist
extends RefCounted

## A step's state.
const PENDING := &"pending"
const DONE := &"done"
## Its phase was left behind before it was done.
const MISSED := &"missed"

## Characters of a message the link carries per metre of survey it could
## carry, so a message takes the link's own time: a moment up the open tunnel,
## minutes through sealed rock. Tuned for play (ADR 0001).
const _CHARACTERS_PER_SURVEY_METRE := 40.0

var _scenario: Scenario
## The phase now running, an index into the Scenario's phases.
var _phase := 0
## Each phase's step states, matching the Scenario's phases and steps.
var _states: Array = []
var _achieved := {}
## Indices of the messages sent, by index.
var _sent := {}
## Indices of messages sent and not yet arrived, oldest first.
var _on_the_way: Array[int] = []
## Characters of the oldest message on the way that have arrived.
var _arriving := 0.0
var _arrived: Array[String] = []


func _init(scenario: Scenario) -> void:
	_scenario = scenario
	for phase in scenario.phases:
		var states: Array[StringName] = []
		states.resize(phase.steps.size())
		states.fill(PENDING)
		_states.append(states)


## Evaluates the Scenario against the simulation after a step of `dt`
## simulated seconds, given the events raised since the last tend. Raises its
## own events into `out`: &"checklist_step" {phase, step, id, state} as a step
## is done or missed, &"checklist_phase" {phase, title} as a phase begins,
## &"goal_achieved" {id, text}, &"surface_message" {text} as one arrives.
func tend(sim: DiveSimulation, events: Array, dt: float, out: Array[Dictionary]) -> void:
	for goal in _scenario.orders:
		if not _achieved.has(goal.id) and goal.achieved_when.call(sim, events):
			_achieved[goal.id] = true
			out.append({type = &"goal_achieved", id = goal.id, text = goal.text})
	_tick(sim, events, out)
	for i in _scenario.messages.size():
		if not _sent.has(i) and _scenario.messages[i].sent_when.call(sim, events):
			_sent[i] = true
			_on_the_way.append(i)
	_deliver(sim.link_capacity() * _CHARACTERS_PER_SURVEY_METRE * dt, out)


## Ticks the steps in order, one event counting toward one step: once a step
## ticks, the steps after it see only the simulation's state this tend. A
## phase begins once the one before is finished, or early when its own
## begins_when holds; the steps of every phase before it left undone are
## missed.
func _tick(sim: DiveSimulation, events: Array, out: Array[Dictionary]) -> void:
	var unspent := events
	while _phase < _states.size():
		var next := next_step_index()
		if next >= 0:
			var step: Scenario.Step = _scenario.phases[_phase].steps[next]
			if step.done_when.call(sim, unspent):
				_set_state(_phase, next, DONE, out)
				unspent = []
				continue
		if next < 0 and _phase + 1 < _states.size():
			_begin(_phase + 1, out)
			continue
		var early := _early_phase(sim, events)
		if early < 0:
			return
		_begin(early, out)


## The first phase after this one whose begins_when holds, or -1.
func _early_phase(sim: DiveSimulation, events: Array) -> int:
	for i in range(_phase + 1, _states.size()):
		var begins: Callable = _scenario.phases[i].begins_when
		if begins.is_valid() and begins.call(sim, events):
			return i
	return -1


func _begin(phase: int, out: Array[Dictionary]) -> void:
	for p in range(_phase, phase):
		for s in _states[p].size():
			if _states[p][s] == PENDING:
				_set_state(p, s, MISSED, out)
	_phase = phase
	out.append({type = &"checklist_phase", phase = phase, title = _scenario.phases[phase].title})


func _set_state(phase: int, step: int, state: StringName, out: Array[Dictionary]) -> void:
	_states[phase][step] = state
	out.append({type = &"checklist_step", phase = phase, step = step,
			id = _scenario.phases[phase].steps[step].id, state = state})


## Carries `characters` of the messages on the way, oldest first.
func _deliver(characters: float, out: Array[Dictionary]) -> void:
	_arriving += characters
	while not _on_the_way.is_empty():
		var text := _scenario.messages[_on_the_way[0]].text
		if _arriving < text.length():
			return
		_arriving -= text.length()
		_on_the_way.pop_front()
		_arrived.append(text)
		out.append({type = &"surface_message", text = text})
	_arriving = 0.0  # Nothing waiting: the link does not bank its time.


# --- State -----------------------------------------------------------------

func title() -> String:
	return _scenario.title


func phase() -> int:
	return _phase


## The index of the next step to do in the phase now running, or -1 if none.
func next_step_index() -> int:
	if _phase >= _states.size():
		return -1
	return _states[_phase].find(PENDING)


## The next step to do as a step of phases() plus its {phase, step} indices,
## or {} when none is left.
func next_step() -> Dictionary:
	var index := next_step_index()
	if index < 0:
		return {}
	var step: Scenario.Step = _scenario.phases[_phase].steps[index]
	return {id = step.id, text = step.text, station = step.station, action = step.action,
			state = PENDING, phase = _phase, step = index}


func orders() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for goal in _scenario.orders:
		result.append({id = goal.id, text = goal.text, achieved = _achieved.has(goal.id)})
	return result


## The deepest target depth a goal of the Orders sets, NAN if none does.
func target_depth() -> float:
	var deepest := NAN
	for goal in _scenario.orders:
		if not is_nan(goal.target_depth) and (is_nan(deepest) or goal.target_depth > deepest):
			deepest = goal.target_depth
	return deepest


func phases() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for p in _scenario.phases.size():
		var steps: Array[Dictionary] = []
		var phase: Scenario.Phase = _scenario.phases[p]
		for s in phase.steps.size():
			var step: Scenario.Step = phase.steps[s]
			steps.append({id = step.id, text = step.text, station = step.station,
					action = step.action, state = _states[p][s]})
		result.append({title = phase.title, steps = steps})
	return result


func arrived() -> Array[String]:
	return _arrived.duplicate()


func on_the_way() -> int:
	return _on_the_way.size()

# Scenarios and the Checklist

**Scenarios.**
A Scenario (`sim/scenario.gd`, `Scenario`) is plain data: a title, a layout, a start state (`prepare`, a Callable given the simulation at the start of each of its dives), the Orders (`Scenario.Goal`), the Checklist (`Scenario.Phase`s of `Scenario.Step`s) and surface control's messages (`Scenario.Message`).
Every condition is a `Callable(sim, events) -> bool` that reads `DiveSimulation`'s public interface only; build one with `Scenario.when()` (a state) or `Scenario.on_event()` (an event, optionally matching), or the helpers beside them.
`Scenario.start()` makes its dive; `set_scenario()` puts a Scenario on any simulation, which is how tests try the First dive's Checklist on a short layout (its conditions read Media by name, never depth).
A new Scenario is a static constructor beside `first_dive()`, listed in `Scenario.all()` (the start menu's order) with a `summary` line; one that needs a start state the commands cannot reach adds a command for it on `DiveSimulation` that `prepare` calls, never a debug command.
Those are the Scenario start commands (their own section, "Scenario start", after the Station commands): `start_below(metres)` (the Head that deep, having cut straight down with its Residual inside the Band all the way: the Column recorded and aboard, the tunnel lined or sealed, the Head fresh and its Counter-waves cancelling the Wobble there, the hull at the rock's temperature;
it moves the Head through `_follow_the_head()` in pieces taking no time, then drops the events the descent raised, since it is history) and `start_dark(head_wear)` (the plasma lost now, by `Plasma._lose()` with cause `&"scenario"`, the Head that worn; what follows, stranded or brought home, happens at once and its events are raised).
Each acts only while `_at_dive_start()` (no time run, the dive not ended) and is ignored after.
`prepare` may also send crew commands (the Shift drill engages the Drive's and Thermal's autopilots and sends a pulse, so STANDBY has a guess to pretune against).
A Scenario with two ways through (Stranded in the granite: relit, or still dark) lays them out as phases in one line, each branch beginning early on its own event; a phase reached only by coming next after a finished one is left behind in the same tend when a later phase's `begins_when` already holds, so the crew never sees it.
Progress is `Checklist` (`sim/checklist.gd`), owned by `DiveSimulation` and tended after every step (`_tend_checklist()`, from `advance()`, and while surfaced, so messages still arrive) with the events raised since it last looked (`_events_checked`; events taken by `take_events()` before it saw them wait in `_events_unseen`).
Debug commands that call `_step()` directly (`debug_skip()`, `debug_next_boundary()`) do not tend it: their events reach it on the next `advance()`, but a state passed through mid-jump is not seen.
It breaks the subsystem rule on one point: it is handed the simulation on each `tend()` so the conditions can read it; it holds no reference between calls.
The rules it keeps: goals are achieved once and stay so; steps tick in order, only the next step of the running phase can tick, and an event counts toward one step (the steps after one that ticks see only state that tend); a phase begins once the one before is finished, or early when its `begins_when` holds, and steps left undone before it are `MISSED`;
a message is sent once its condition holds and arrives after its length at `link_capacity()` (fast up the open tunnel, a trickle through sealed rock), one at a time, oldest first.
A message is sent once a dive unless it names when it may be sent again (`Message.again_after(condition)`): once that has held since it was sent, its own condition sends it again.
**Phase triggers.**
A phase's `begins_when` holds only on something the simulation reports the dive doing: a state the vessel is in (below the surface, `Scenario.settled_in(medium)`: in that Medium with the Residual inside the Band, `Scenario.climbing()`, surfaced) or an event of the dive (`&"boundary_approaching"`, `&"relight_result"`, `&"surfaced"`).
It never holds on what the crew intends: a plotted Course (`&"course_plotted"`, `course_pitch()`), an engaged autopilot, a setting, `&"orders_read"`, a pulse.
Intentions tick steps, so a phase that needs one asks for it in a step: "Turn and climb" begins early when the Lithocraft is climbing (pitch above level and moving), and its first step reads `course_pitch()`, ticking at once if the climb is already plotted.
`test_no_phase_begins_early_on_what_the_crew_only_intends` (`test/scenario_test.gd`) lists every Scenario's early triggers and tries each against every intention command on a dive that has not run; a new trigger is added to its list.
The intention commands are not listed by hand: `_state_every_intention()` finds every public command of `DiveSimulation` by reflection (a public method that returns nothing) and sends each, the crew at every Station, so a new crew command is tried against every trigger with nobody remembering.
`NOT_AN_INTENTION` holds the few it does not send (the time step, a new dive, the Scenario start commands), each with its reason, and `_intention_arguments()` the arguments that cannot be made up from their types.
`test_every_public_command_is_an_intention_or_listed_as_not_one` fails on a command that is neither sent nor listed.
A new dive starts the Checklist afresh (`_scenario` is kept between dives).
Step texts name no keys: a step's `action` names the key-map action that does it, and the panel writes `KeyMap.label(action)`.
A step that may take a second control names it with `Step.and_also(action)` (`also` in the step's dictionary), and the panel writes both: every "Pretune standby" step names `tune_frequency` and `tune_amplitude`.
Events a Scenario's conditions need that the simulation did not raise are added to it as ordinary events (`&"course_plotted"`, `&"pulse_sent"`, `&"orders_read"`).
**Messages follow what the dive does.**
A message's `sent_when` keeps the phase triggers' rule: surface control speaks of what the Lithocraft does or what has happened to it, never of what the crew only intends.
The First dive's "Turning for home: you will deepen through the turn." is sent on `Scenario.turning_for_home()`: a climb plotted and steered for, the Head still cutting below level, moving, and being steered round (`steering()` above nothing), so a climb plotted at rest, or in the moment of plotting, sends nothing.
It is the only place the crew is told the turn deepens when the climb is plotted before "Turn and climb" begins, since that phase's two steps then tick in the same moment; it adds no step.
It is sent once for each turn for home: stopping mid-turn or replotting the climb is the same turn, and it may be sent again only after the climb has been given up for a Course that is not one (`course_pitch()` level or diving).
A turn to a level or diving Course, and a climb the Drive is nudged into off a diving Course, send nothing.

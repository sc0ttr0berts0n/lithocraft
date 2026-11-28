# The Checklist follower

`test/checklist_follower_test.gd` plays the First dive and the Glide drill by their Checklists alone: it reads `next_step()`, has its table's entry for that step send the command the step's key sends, and steps time (run fast, as the time key does) until the step ticks.
It is the play-test bar held by a machine: the First dive finished cold, surfaced and paid with target A identified, by doing only what the Checklist says, and again after one unasked Course key at the surface (#73, #128).
A new or renamed step needs an entry in its Scenario's table (`_first_dive_table()`, `_glide_drill_table()`; the steps out of a Glide, shared, in `_out_of_the_glide_table()`): the step's own `action` and how the crew follows it; a step with no entry, or an entry naming another action, fails the follower by name.
An entry sends only what its step asks for, when the crew could see it is time (a Shift once the Head is in the Medium named, a pretune only to the scan's guess, a pulse at Quiet Ship only once the vessel is still and silent), so a step the crew cannot do from what the Checklist has asked so far fails there: fix the Checklist, never the entry.
It tunes as a hand does: the channel selected first, then the Reactor's keys a press at a time at the normal time rate (`_tune_by_keys()`), so a tuning step is only as reachable as it is for the crew.
A step that does not tick within its time limit, or is left `MISSED`, fails naming the step and its phase.

## Kinds of entry

- **Once**: a key pressed if its setting is not yet so (`_engage()`, `_quiet()`, `_beam_pulsing_on()`, `_start_glide()`, `_plot_glide_all()`).
- **A press each look until the step ticks**: a key held, in effect, until a condition the Checklist names (`_quiet_pulse()` until Navigation shows the Glide home, `_narrow_the_beam()` until a narrow pulse, `_lengthen_glide()` until the plot is long enough, the tuning keys).
- **Wait**: a step that names no key (`_wait()`): the crew waits for the Lithocraft to do it (come round onto the Course, cut into target A, record it).
- **Fly the Glide**: `_hold_the_line()` reads only what the Drive shows (the ball's OFF LINE figure, `glide_off_line()`, and the range left) and nudges back toward the line a few presses a look, as `DiveTestKit.fly_glide()` does; the Glide drill's step names the Drive's autopilot instead, and its entry engages it.
- An entry with `fast = false` is worked at the normal time rate (nobody tunes, or flies a Glide, with time running fast); one with `look` looks that often in place of `LOOK_S` (`GLIDE_LOOK_S` while a Glide is flown).
- It never acknowledges a call, since no step says to: a warning that holds the time rate at 1 only slows it.
  It keeps the normal rate while its phase has a feature still to observe (`_observing_ahead()`).

## What it measures

The design record keeps what each followed dive measured (time, the Head's and hull's wear, pay); a change that moves them much is a design change, recorded there with its reason.

# The second checkpoint

Grilled with the developer on 25 November 2026, getting back on course after round 2's tickets (#31 to #43) piled up as unmerged PRs.

- **A checkpoint has the shape of the first.**
  Every ticket of the round merged to `dev`, the whole suite passing headless, one playable build with no tweaks in between, then a cold, narrated, recorded play test (First dive, then the drills) written up in `docs/playtests/`.
  No new tickets join a round once it is cut; new ideas wait for its play test.
- **`main` stays one stable build behind.**
  Checkpoint 1 (the build played on 25 November) was promoted to `main` (#18); each later checkpoint gets its own promotion.
- **Agents merge into `dev`** once a PR is up to date with `dev` and the suite is green, and stop to ask only when a conflict forces a design choice.
  Overlapping PRs merge one at a time in one session.
  Tickets are built one session each, in parallel where their files do not overlap; the explainer (#33) goes last because it covers every reading on every screen.
- **Choices from round 2's PRs, accepted:** the Shift dial is a selector and does not disengage the Reactor's autopilot (only R does); the Drive's override holds after the crew walks away, ending on O or on engaging the Drive's autopilot; the Shift match is shown against the window narrowed by Head wear, so what is seen is what is graded;
  the Checklist ticks strictly in order (a step done early is redone, steps left behind show as missed), to be judged in play; the point cloud's camera angle, 90 s fade and 2,000-point cap are judged in the play test, not tuned before it.
  Enter is ignored during the end-of-dive lurch so it cannot skip the outcome screen.
  *Superseded in part (After the second checkpoint): the Drive's override is replaced by nudges, and the Shift match and window by the Residual and the Band.*
- **The play test's bar:** the First dive is finished cold, from the Checklist and explainers alone, surfacing and paid without asking what to do.
  Held loosely: the developer designed the game and is not a true cold player, so being stuck for other reasons is a finding, not a failure.
- **"Not yet designed" stays parked** until after the second play test, then is ranked by what it shows.
- **Found in merging: the MATCH meter and "ready the dial" disagreed.**
  The meter (#36) compared the dial to the wobble of the Medium the Head is in, while the Boundary call and the Checklist (#34) ask the crew to set the dial for the Medium ahead, so readying the dial correctly made the meter fall.
  *Superseded (After the second checkpoint): MATCH is retired.*
- **The Shift dial as a radio's active and standby channels (developer's idea).**
  "It might be cool for the interface to work like a flight control channel selector.
  You can tune the next behaviour and then when you MATCH you just [switch] from channel to channel."
  Real basis: an airliner's VHF radio holds an active and a standby frequency; the crew tunes the standby ahead of time and a transfer (flip-flop) key swaps them in one press.
  Here the dial tunes the standby while the active holds the plasma, and the Shift is the swap, so readying the dial and making the Shift are separate acts, the second a single press timed to the crossing.
  *Superseded in part by "The Reactor cancels the rock's wobble" (After the second checkpoint): ACTIVE, STANDBY and the swap on R stay; MATCH, the Shift's grade and lateness in the sub-bullets below are retired.*
  - **Two lanes, ACTIVE and STANDBY, each with its own MATCH.**
    ACTIVE against the wobble of the Medium the Head is in; STANDBY against the wobble expected in the Medium ahead, shown once the Boundary-approaching call comes.
    N/M tune whichever channel the crew is on (developer's refinement), not only the standby.
  - **R swaps the channels, and the swap is the Shift**, graded as a Shift is: the new active's match to the wobble at that moment, then lateness.
    A swap made early, still in the old Medium, is a poor Shift; a late one is punished by the window.
  - **The old active drops to standby**, so a second press swaps back; swapping back is a Shift too, so undoing an early swap costs a second one.
  - **Homework buys a preview (developer's idea).**
    "If you do your homework you can know a bit about the next rock (good scans, etc.) and maybe you can get a sine wave that is noisy, and the better you do you get a preview on the sine wave to come on the standby channel."
    The STANDBY lane shows the projected wobble of the rock ahead, noisy in proportion to how little the scans know, so pretuning is a reward for scanning well.
    Real basis: seismic and sonar surveys estimate the properties of rock ahead from echoes, and the estimate sharpens with more and cleaner returns, which is why Quiet Ship exists.
  - **The preview is a sum of sines (developer).**
    Not a pure wave with noise on top: the true wobble of the rock ahead summed with spurious sines, "dissonant but correct", and better homework shrinks the spurious ones until the true sine stands out.
    Real basis: every signal is a sum of sines (Fourier); seismic surveys stack repeated shots, and stacking reinforces the coherent echo while incoherent ones cancel.
    Confidence comes from the Inferred Boundary ahead (#40, points alone, so Quiet Ship pulses and more points sharpen it); no scan leaves the lane spurious sines only.
  - **A poor scan can mislead.**
    The projected wobble is off the truth by an error that shrinks with confidence.
    STANDBY's MATCH reads against the projection, the Shift is graded against the truth, so even good homework may leave a trim to do after the swap.
    "You're not going to get the full picture unless you really do a tight analysis, and even then it's still going to be a sum of sines."
  - **Tuning ACTIVE moves the live plasma freely**; the plasma suffers only from being off its match, how far and for how long, and reaching a match counts as a Shift graded with the lateness built up.
    Pretuning STANDBY and swapping on the crossing is the smart play; a trim on ACTIVE fixes a near miss cheaply.
  - **ACTIVE shows the real wobble, clean**: the Head measures what it is cutting; only the look-ahead is uncertain.
  - **Keys:** C selects which channel N/M tune (starting on STANDBY, staying there after a swap); R swaps.
  - **Built before the second play test**, as a fix to #36, before the explainer (#33) so it describes both channels.

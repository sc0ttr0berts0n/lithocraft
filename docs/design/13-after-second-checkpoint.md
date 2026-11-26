# After the second checkpoint

Grilled with the developer on 25 November 2026, from the second play test (`docs/playtests/2026-11-25-second-checkpoint.md`).

- **Play-test records.**
  The write-up and transcript live in `docs/playtests/`; frames that support a finding may be committed beside them.
  The video itself will be deleted in time, so nothing may depend on it.
- **A Checklist phase begins early only on what the Lithocraft does** (a Boundary crossed, the vessel actually climbing), never on a plotted Course: a Course is an intention, not a fact.
  A climb plotted at the surface leaves the Checklist where it is.
- **Wear builds while the plasma runs mistuned past the window,** not in one lump at the late Shift: the Head wear reading climbs live, with an alarm that grows.
  The Shift then costs only for its match, so engaging the autopilot can never be the step that wrecks the Head.
  Real basis: the damage is done by the running, not by the fix.
  *Superseded in part by "The Head wears only while the Residual is outside the Band", later in this section: there is no window.*
- **The plasma's steadiness shows its causes as indicator lamps (developer's idea).**
  "UNSTEADY 73%" is a formula of several things; each one that is pulling it down lights its own lamp (Head worn now, mistuning, more to come).
  Real basis: an airliner's annunciator panel, one labelled light per fault.
- **Key wording is not worth polishing.**
  Keys are a stand-in until Stations get diegetic controls (handles, levers, buttons); "the Shift" read as the Shift key is left alone.
- **Tuning stays one control, frequency.**
  Phase and amplitude may earn a place later.
  What must change is legibility: what every wave and colour on the Reactor screen means.
  *Superseded by "Two controls, frequency and amplitude; phase locks itself", later in this section.*
- **The Boundary's timing, with its doubt.**
  The Reactor shows the time to the Boundary as a countdown with a plus-or-minus from the scan's confidence (seconds when well scanned, up to a capped "unknown" when not), then the Shift window counting down.
- **The Lithocraft goes forward only;** the way home is turn and climb.
  The play test's "back out the hole" was a wrong assumption, not a wish.
- **Navigation projects the path ahead** at the current turn rate and speed, as an airliner's navigation display does, on the map.
  A real dive plan (legs: turn, go straight 100 m, turn again at another radius) is wanted later ("a flight plan or a dive plan, that could be cute"); for now the projection is enough.
- **No HUD stays.**
  The developer's helmet-display idea (the F3 readings all the time) is parked under Not yet designed.
  Real basis: pilots' helmet-mounted displays.
- **Screens are designed, not typed (developer).**
  Station screens have been built the way developers conventionally dump text: lines of type and line breaks.
  The developer wants real compositions, pushed further and faster, using everything known about flat-screen layout ("you need not act like a developer of old").

- **Navigation plans, the Drive deviates.**
  The Course is the plan; the Drive goes off it only by nudging pitch and heading (its dive / level / climb keys go), and its flight display shows the Course and the deviation side by side.
  What the play test uncovered: the Course is only a direction (heading and pitch), 1/2/3 are shortcuts for straight down, level and straight up, and a climb from straight down is a half-circle of at least the turn radius that deepens before it rises.
- **The point cloud needs a visual redesign.**
  Head-up puts the world's down at the top of the screen in a dive, and a "down is down" camera was not enough of an answer for the developer: "this is a bad design then and isn't very clear … I would make an effort to redesign this visually."
  The moving map, with its honest depth, is the part that reads.
- **The projected path is drawn on the map and among the scanned points,** out through the current turn and a straight stretch beyond.
- **A directional scan (developer's idea).**
  "Maybe the scanner can somehow be more directional so that you can scan ahead for these kind of problems."
  Real basis: phased-array sonar and radar steer a narrow beam by timing their elements; a narrow beam puts the same energy into a smaller cone, so it reaches further and resolves finer there and hears nothing elsewhere.
  Parked under Not yet designed.
- **Stations as web pages (developer's idea, "a long shot").**
  "Maybe you could make them an actual grid of 6 HTML pages, and I would play them alongside the game, opening Godot, and it would pass the data in.
  Thinking forward to multiplayer, this would actually be a crazy way to get a second player.
  They're literally at a station."
  It fits the simulation's one seam (commands in, state and events out): a page is just another view.
  Real precedent: Artemis Spaceship Bridge Simulator gives each player a networked Station screen, and home-cockpit builders run instruments on second screens fed by the simulator.
- **Caution lamps** is the term for the indicator lamps (see `GLOSSARY.md`); "warning" is kept for what is about to kill the crew.
- **The Boundary countdown caps at "> 5 min"** when the scan cannot say better (the developer left the figure to the agent, leaning to 5 or 10 minutes; tuned for play).
- **Small fixes taken as stated:** a softer autopilot tone; key lists that are not cut off; a Thermal gauge of hull temperature against what the hull bears; an observed feature shows in the Column.

- **Pure Godot for now.**
  Stations as web pages, and the second player they would allow, are dropped for the present (the idea stays recorded above).
  The screens are still redesigned, inside Godot.
- **Grills are about concept; the agent decides what goes in a round.**
  The developer: "we should be asking questions about the concept", not approving a ticket list item by item.
- **The next play test repeats this one's bar:** the First dive finished cold, surfaced and paid, from the Checklist alone.

- **Designs are tried in Godot itself.**
  Candidate views (the point cloud's above all) are built as switchable views flipped with a debug key during a dive, judged where they will live with real data moving through them.
- **One colour language on every screen, an airliner's:** white is what is happening now, cyan what the crew has selected or aims for, green engaged and working, amber a caution, red a warning.
  The developer: "I love it when you pull from Airbus and airplane cockpit stuff."
  Each Station's own tint, which meant nothing, goes.
  Real basis: Airbus's flight-deck colour philosophy lets a pilot read an unfamiliar display by colour.
- **The Reactor cancels the rock's wobble (developer's idea).**
  Not matching a rhythm but making its inverse: "you have to make the inverse wave of the wave that the rock creates.
  And if you do a good job of this, they will cancel out and you'll get a straight line.
  And if you do a poor job, it will have a certain amplitude or some frequency nonsense that can't be cancelled out."
  What is left over must stay inside a band.
  Real basis: tokamaks hold their plasma this way, sensing a growing magnetic wobble and driving feedback coils with the opposite field to cancel it (resistive-wall-mode and error-field control); it is the principle of noise-cancelling headphones.
  - **The band is the Head's health.**
    A fresh Head tolerates a wide band and takes little damage from a rough tune; "the band would get more narrow as the head takes damage, so that you have to get a more perfect tune to jump between materials."
    This replaces the wear-narrowed window as the picture of Head wear.
  - **Two controls, frequency and amplitude; phase locks itself** once the frequency is close.
    Each mistake has its own look in the Residual: a wrong frequency swells and fades in slow beats, a wrong amplitude leaves a small steady wave, so the picture says which control is off.
    Real basis: a phase-locked loop holds phase by itself once near in frequency, as a radio holds a station.
    (The developer had raised that amplitude or phase may matter more than frequency.)
  - **The Head wears only while the Residual is outside the Band,** faster the further out.
    This replaces the Shift window and the late Shift, and is the picture for "wear builds while mistuned": line inside the Band, no damage.
    A Boundary is the moment the rock's Wobble changes and the old Counter-wave stops working.
  - **Heat narrows the Band as wear does,** with a HOT Caution lamp on the Reactor; the Band is seen easing live as things cool or change (developer: "seeing the band ease up live when things change would be really cool").
    This replaces a hot hull making a poor Shift wear harder: the relationship stands, shown where the crew is looking.
  - **STANDBY keeps its job:** a Counter-wave prepared for the rock ahead, against the scan's noisy sum-of-sines guess of its Wobble, with its own predicted Residual; the swap at the Boundary is still the Shift.
    Good scans sharpen the guess; a poor one can mislead.
  - **Terms:** Wobble, Counter-wave, Residual, Band (see `GLOSSARY.md`).
    MATCH is retired.
- **Stations should look different from one another in the end;** a label is the fallback, not the aim.
- **A taller Habitat.**
  "Can we get ourselves in something about the ratio of a can of beans?
  I feel like we're in a tuna can right now.
  No major changes, just make it taller."
  About 9.5 m tall against 6.6 m across.
  - **Stations slide to the new floor when "down" reverses (developer's idea).**
    "Let's make it so the stations can slide to the new ceiling when gravity reverses."
    - They slide only when "down" flips from one end to the other (dive to climb, or back), settling at working height above whichever end is now the floor; level or coasting, they stay where they last were.
      Real basis: a carriage on a rail along the wall; the Stations already pivot to stay upright.
    - **The Arm's ring slides along the Bore too (developer).**
      It travels with the Stations, and it first runs along the Bore to find the crew member wherever they are along its length ("it's possible they might not be at one end or the other"), catches them, then carries them to the Stations.
    - **A Station that pulls away breaks what you were doing (developer).**
      "If you're pushing a button and it moves, you can't push the button anymore."
      A held or continuous action stops when the Station slides out of reach.
      This is not a reach check before every command; only the pulling away matters.
    - **In the Arm you ride along.**
      The Arm's ring slides with the Stations, so a crew member it holds keeps working through the slide; on foot the Station leaves you.
      Getting into the Arm before the turn is crew skill.
      (The developer: "What a wonderful edge case.")
    - **The slides are free** for now: no power, no failure.

- **Round 3's spec is issue #71**; its tickets (cut by the agent from the above, sub-issues of #1): #59 Checklist triggers, #60 the Reactor cancels the Wobble, #61 STANDBY's preview and the countdown, #62 screens as compositions, #63 the Reactor screen, #64 the Thermal gauge, #65 Navigation plans and the Drive deviates, #66 the projected path, #67 point cloud candidates,
  #68 the taller Habitat, #69 sliding Stations and Arm ring, #70 features in the Column. #57 and #58 are superseded by #60 and #61; the explainer (#33) waits for the screens.
  Tooling tickets from the session's retro (CI, a Checklist-follower test, splitting these docs, a screenshot helper, the play-test toolkit) are #72 to #76.

# Round 4, as built, continued further still

The tickets of round 4 (spec #113), as built, continuing 22-round-4-as-built-continued-once-more.md once it was full.


## The seams between the Glide, the Sweep and targets (#159)

Faults the review of round 4's code found where its tickets meet, fixed with a test each that fails with the fix undone. How each meets the code is in `docs/conventions/glide.md`, `targets.md`, `screen-navigation.md` and `cost-budget.md`.

- **A Glide that crosses nothing keeps what was known when it began.** A second Glide started from the idle of the first held, at its end, the true Wobble of the rock at full confidence: the layout's truth handed to the scan side.
  Now the Glide begins with the guess held (or, from the Crawl with nothing held, the Wobble felt on the plasma, which ACTIVE was cutting) and ends holding it unless it crossed a Boundary.
- **Two Boundaries in one step.** Suspected by the review, and shown: a 2.5 m layer met at the top time rate in one 1 s step left the Glide holding the guess of the layer, not of the rock beyond it. The look-ahead now looks on past each Boundary a Glide crosses, at once.
- **The dive's end ends a Sweep.** Dying or coming to the surface left a Sweep running, its band and label frozen on the outcome screen; both now end it, as a stranding did.
- **A Glide that ends inside a target.** The orchestrator's ruling in the developer's absence, to be confirmed: crawling out through the rest of the body puts it in the Column, as long as the rest of it, so it can be observed and identified, since crawling through it is what identifies it; the part glided through is never seen.
- **The Glide's reach, asked two ways.** Navigation's screens and the Checklist ask along the Course, the refusal along the Head; one remembered answer was worked out afresh by turns while a Glide waited. Each way now keeps its own, and the cost budget plays a condition with a Glide plotted and waiting.
- **The Sweep seen along its axis.** Diving, the plan looks straight down the Sweep's axis and both its bands were edge-on, their edges lost under the survey's points. The swept cone is now drawn round its axis too, a faint ring with a strong leading ring, and the leading edge goes over the points; Navigation's recipe has the Sweep halted diving and level in every view.

Left for the developer, as the ticket said: whether `start_glide()` should leave the Drive's autopilot engaged, and whether the off-line call should be a report, not a warning, while the autopilot holds the Glide.
*Decided by the developer in #161: yes to both (below).*


## A tighter turn, and a Glide the autopilot holds (#161)

The developer's three changes before the play test of rounds 3 and 4 ("we'll try it this way", 28 November 2026), each number a starting point to tune in play. How each meets the code is in `docs/conventions/stations-and-autopilots.md`, `glide.md`, `checklist-follower.md` and `cost-budget.md`.

- **A much tighter turn.** The tightest turn is about 60 m in radius (it was 250 m), and the Drive's autopilot steers at half effort (it was a quarter), so its turn for home is about 240 m across and 120 m deep, not a kilometre.
  The relationships stand (ADR 0001): a tighter turn takes more steering effort and heats one side of the rim harder, and a faster vessel turns wider. The first design session's "hundreds of metres" is overtaken; its principle, that the turn makes route planning a decision, is not.
  The projection's sampling still suits it (agent's choice to keep it): a 5 m piece is under 5 degrees of a 60 m arc, and its 4,000 m follows a quarter turn steered at a fortieth of full effort.
- **Starting a Glide leaves the Drive's autopilot as it is.** The one Drive command that does: the autopilot may hold a Glide's line loosely, so one crew member can glide while working another Station. A nudge in the Glide still disengages it.
- **Off the line is a report while the autopilot holds the Glide.** Its loose rule lets the Glide ride just past the sheath's slack, so as a warning it sounded one to three times a Glide and dropped the time rate each time. On the autopilot the Drive's screen and call light still show it, and its wear is unchanged; flown by hand it warns as before.
  Agent's choice: a report that becomes a warning (the autopilot let go while off the line) sounds again and drops the time rate, as a new warning would.
- **The survey now covers the way home (agent's choice).** The ticket took the turn's 240 m across to lie inside the survey's 256 m square, but the square is centred on the line down and the climb runs a full turn's width off it, 240 m out against 128.
  Outside it, the narrow Beam needed hundreds of clean pulses for the sandstone's Boundary 680 m up (it did before too, at a time rate a warning held at 1), and the faint, scattered echoes then put it too high, so the Glide ran on into the sand.
  So the survey also covers a patch where that turn climbs: one autopilot turn across along the Head's heading at the start, 48 m along it and 144 m across it, so a Course a heading step off still climbs inside; the ground cut straight down and back up through, as its constant always said.
  A square over both (8,192 points) was tried and put the cost budget far over: Navigation's drawing grows with the survey's points. The patch adds 216 to the 2,048, and its scatter is drawn apart, so the first square and the targets' places are as before.
- **The Prospecting drill's target moved onto the line the keys can plot (agent's choice).** One pitch step off straight down is 15 degrees, and the tighter turn comes onto it within metres, so the target 12 m off at 120 m below was passed by; only the kilometre-wide turn had curved into it. It now lies 32 m off, on that line, and a dive straight down still passes it by.
- **The Glide home's scan step ticks on a pulse (agent's choice).** The survey now shows the Glide home before any pulse, so "Pulse until Navigation shows the Glide home up through the sandstone" ticks on a clean pulse at Quiet Ship after which it shows, not on the showing alone: every step ticks on a deed. The narrow Beam's step stays; it is still how the Beam reaches the Boundaries above.
- **The Glide home is held on the autopilot until a nudge.** The Drive's autopilot, engaged on the surface, now still holds the Glide, so the hold step says so: nudge toward the ball's diamond to hold it closer, which takes it off the autopilot. The follower starts the Glide at the normal rate, as the hand that will fly it does.
- **The Glide drill still engages the autopilot by its Checklist (agent's choice).** It begins with the Drive's autopilot off, so its E is still the drill's one lesson that the autopilot can hold a Glide, now one it no longer has to be pressed again for.

### What the follower measured

- **The First dive**: about 7,700 s of dive time (it was 30,900); the turn for home about 380 m and 3,200 s (it was 3,100 m and 26,100 s), 120 m deep, not 1,000; Head wear about 0.9% (0.6%), hull wear nil (0.01%); paid about 1,900 (4,700); the Glide 667 m, from 780 m deep in the granite to about 115 m in the sandstone, flown by hand.
  The pay falls with the turn: the long turn surveyed about 3 km of granite, and survey pays by the metre. That is the turn's cost, and a design change for the developer's eyes; nothing here makes it back.
- **The Glide drill**: unchanged, about 330 s, the Glide 300 m on the autopilot, Head wear about 1.4%, hull wear about 0.7%, paid about 40.

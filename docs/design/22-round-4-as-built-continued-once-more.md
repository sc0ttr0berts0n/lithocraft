# Round 4, as built, continued once more

The tickets of round 4 (spec #113), as built, continuing 21-round-4-as-built-continued-again.md once it was full.


## The scan views' words and marks (#151)

Agent's choices, the developer away. Round 4's tickets each added words or marks to Navigation's three candidate scan views, and seen together they collided; nothing any view shows changed, only where its words sit and how its marks read. How it meets the code is `docs/conventions/screen-navigation.md`, "The words on the scan display".

- **A strip under the views for the tools' state.** The Sweep's line over the Beam's, each in one place in every view, below the panes rather than over them, so a tool's label never covers the scan, a scale or the expected rock's name.
  It costs the panes some 48 of the display's 209 pixels of height, about what the old labels already covered; the views keep their scales by their own rules, so they shrink a little and never turn or zoom on their own.
- **Every other word placed, never drawn blind.** Inside a pane, the title goes first, then the forward scope's ring ranges, then surface control's rock names, then the other scale words (a depth, DOWN, N, "+100 m"), then a target's name; each takes the first of a few nearby places clear of the words before it and of the vessel's and aim's marks, or is left out.
  The scope's range comes before a rock's name because a scope without its range cannot be read at all; a depth or "+100 m" has a place either side of its line, or a neighbour that says the same, so it gives way to the name, which may also move a line further into the rock, or to the pane's left, and still name the same depth.
  Where every second range ring's number would crowd, every fourth is named.
- **Words on faint backdrops**, as the rock's names already were, so the points never hide them.
- **The survey's points are small open crosses**, not hollow squares: at the size the sheet shows the screen, a hollow square read as a filled one. A cross is still the legend's grey and faint, so nothing reads as a caution.
- **Harder rock's strokes slant across the band and softer rock's dots come in staggered clusters**, drawn over the points: before, the dots lay under the points and were lost, and the strokes, straight down the band, read like the points' own smear. Slanted strokes against speckle is the geological section's own convention for hard rock and sand.
- **A target beside the rock bands.** No Scenario puts a scanned Boundary near a target: the Prospecting drill's one Boundary in reach is the granite's top, some 54 m behind the vessel and known only from the survey. The recipe's tile shows that pairing in the section; a nearer one would need a Scenario change, left for when targets get a Scenario of their own.

## The First dive teaches the loop, and the Glide drill (#128)

Agent's choices, the developer away. How they meet the code is `docs/conventions/scenarios-and-checklist.md` and `docs/conventions/checklist-follower.md`.

### The First dive, reworked

Its phases, in order: Startup (read the orders, the Reactor's and Thermal's autopilots, plot the dive, the Drive's autopilot); the sand (the Beam's own pulsing, a Quiet Ship scan, Quiet Ship off, observe a feature);
the first Boundary and the sandstone (pulse, pretune, Shift, tune ACTIVE, observe, upload, and the same for the granite); the granite (observe); Target A (halt at Quiet Ship, Sweep, Quiet Ship off, crawl into it, observe it, identified);
Turn and climb; Glide home; Out of the Glide; Into the sand; Surface.

- **Target A lies on the line straight down**, 190 m into the granite, a hematite breccia as the Prospecting drill's. The crew finds it by doing what the dive already asks (crawl on down), halts and Sweeps for it, and crawls through it.
  The Prospecting drill keeps the harder lesson of a target off the line; the First dive teaches only that a target is there to be found.
- **The Sweep is honest, but nearly empty here.** The Beam sees ahead and the Sweep round about; a target dead ahead is already in the Beam's cone, so the Sweep narrows its place little. The step ticks on a finished Sweep with the target narrowed, never on the key.
- **One Glide home, scanned with the narrow Beam at Quiet Ship.** The narrow Beam reaches about 800 m in the granite (sound carries well in it), so a few quiet pulses show both Boundaries above. A wider survey of the way home was rejected: it costs far more pulses for nothing the Glide uses.
- **The Glide stops short of the sand.** A Glide reaches 15 m short of the furthest Boundary the scan shows, and in the First dive that is the sand's: the Glide runs from the granite up through the sandstone, and the sand's Boundary is crawled with a Shift, as the way down taught.
  So no Shift is asked at the granite's Boundary on the way up: the Glide crosses it with no Wobble on the plasma.
- **The Glide is flown by hand in the First dive** (nudge toward the ball's diamond), and on the Drive's autopilot in the drill, so each way is taught once.
- **Surface control explains the Glide's costs** in the message sent as target A is identified (the rough tunnel dims the link, off its line the Head and hull wear, it ends at idle: tune STANDBY for the rock round you and Shift to spin up). The link through sealed granite is slow, so a message sent at the turn would arrive after the Glide; this one arrives well before it.
  The message that said what the Glide ended in was dropped from the First dive for the same reason: it arrived only at the surface.
- **Surface control names target A once identified**: hematite breccia, granite shattered and cemented by iron oxide, with a little copper.
- **The "Turn and climb ticks all at once" wart.** The Reactor's autopilot step is gone (no Shift is asked on the way up, and the Glide replaces the autopilot's climb), and the turn's two steps are followed by the Glide home's, so the Checklist always has the climb's next step to show and never jumps to "Surface" for the whole climb.
- **"Into the sand" begins early only as the Lithocraft climbs across the sand's Boundary**, however it came up: a dive left to the autopilots never glides, and still sees the steps it missed marked so. Being in the sand alone never begins it: that is also the surface and a turn for home made in the sand.


### Steps tick on deeds

- A step that asks for a setting by name (read the orders, plot the Course, engage an autopilot, pretune standby, Quiet Ship with the vessel at rest) ticks on the setting held; a step that asks the Lithocraft to do something ticks only on the deed.
  The Beam's own pulsing ticks on a pulse it sent by itself (the switch set is only an intention until the vessel has covered the ground); coming round onto the climb on `straight_on_course()` (within the Glide's start tolerance, no override); starting the Glide on the vessel gliding; the spin-up on the Crawl begun.
- **Quiet Ship at rest counts as halted.** "Halt at Quiet Ship" ticks on Quiet Ship with the vessel still; set at the surface it ticks at once, since the vessel is genuinely at rest. Accepted: halting is the vessel's deed, and it has done it.


### The Glide drill

Second on the start menu, before the Shift drill: tuning at idle is untimed, so the drill is gentler than the Shift drill's tuning against a Boundary.
It begins halted at Quiet Ship 40 m down in the sand (porous, so the Glide's rough tunnel stays open and its cost to the link shows), the survey in the scan, the Reactor's and Thermal's autopilots on.

- Its phases: Plot and glide (read the orders, pulse at Quiet Ship, plot a Glide of 300 m a press at a time, Quiet Ship off, start the Glide, hold its line on the Drive's autopilot); Out of the Glide (tune STANDBY for the rock round the vessel, Shift to spin up, tune ACTIVE).
- **300 m, plotted with the step key.** It teaches the hold-a-key plot the First dive's "all the scan shows" does not, and ends in the sandstone, so the rock round the idle Head is not the rock the Glide began in and STANDBY must be tuned for it.
- Its goal is a Crawl begun again in the sandstone after a Glide, the Residual inside the Band.
- Surface control says the rough tunnel dims the link once the Glide ends, and "That is the drill" once the Crawl begins.


### What the follower measured

The follower (`test/checklist_follower_test.gd`), by the Checklist alone:

- **The First dive**: about 30,900 s of dive time; Head wear about 0.6%, hull wear about 0.01%; paid about 4,700 (target A identified, worth 400, two features); the Glide about 670 m, from 790 m deep in the granite up to about 125 m in the sandstone, flown by hand at almost no wear.
  Before #128 it was about 31,600 s, Head wear 7.6% and pay about 4,800: the Glide spares the Head the crawled climb through the granite.
- **The Glide drill**: about 330 s; the Glide 300 m on the autopilot; Head wear about 1.4%, hull wear about 0.7%; the link's light about 84% after it; paid about 40.
- **Left to the autopilots**, the First dive still comes home by Crawl, with no Glide (#71, story 24).


### What felt wrong, for the developer

- **The crawled turn is very long.** On its autopilot the Drive steers at a quarter effort, a turn about 1 km across in the granite, about 25,000 s of the dive's 30,900 s even at the top time rate. A turn at full effort would be a quarter as long; it is #126's and the Drive's, not changed here.
- **The Sweep for a target dead ahead teaches the key but not why**: the Beam already sees it.
- **Several steps tick at once** when the crew has done well: tune ACTIVE after a good pretune, tune STANDBY at idle (it still holds the sandstone's wave from the Shift down), Quiet Ship at rest.
- **The Glide ends in the sandstone, not near the surface**, since it stops short of the sand's Boundary; the last 125 m are crawled with a Shift.

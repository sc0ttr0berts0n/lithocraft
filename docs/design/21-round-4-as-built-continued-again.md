# Round 4, as built, continued again

The tickets of round 4 (spec #113), as built, continuing 20-round-4-as-built-continued-further.md once it was full.


## The Glide's tunnel (#125)

Agent's choices, the developer away. How it meets the code is `docs/conventions/glide.md`, "The tunnel and the link (#125)".

- **One rule for both ways of moving.** Each metre of tunnel the Tail leaves is sealed if the rock is dense, whoever cut it (the melt has to go somewhere, ADR 0001), and open if porous: glass where the Head crawled, rough where it glided. The wall is what the Head made of the rock as it passed, so the last vessel length of a glided stretch is rough even though the Tail leaves it crawling.
  So the seal's call and event, the sealed metres, the rescue and the stranding rules are the Crawl's, unchanged; a rough open tunnel is open to a rescue as a glass one is.
- **The light, how the loss adds.** The link up an open tunnel carries the glass rate times the share of light that arrives: each separate run of rough wall passes 90% of the light reaching it, and along rough wall the light falls by a factor of e every 4 km.
  Real basis: a rough-walled light guide loses light where the smooth guide gives way to it and along its length. So one Glide of a few hundred metres leaves about 80 to 87% (the developer's "80% quality vs 100% glass perfection"), a longer one less, and each Glide more a little less again: two of 60 m are worse than one of 120 m.
  Glides with no glass between them are one run. Light is the whole of the open link however dim it gets; it never falls back to sound while the tunnel is open (a dive would need tens of Glides to dim it to sound's trickle).
- **How much slower** follows from that: about a tenth slower after a short Glide, a fifth after one of 500 m; the rate falls as the Tail leaves the glided stretch, through the Glide and the vessel length after it.
- **The call in one step.** At the top time rate a Glide can carry the Tail into dense rock within the step the Head entered it; the Bore Station's "tunnel about to seal" is then still made, once, at its most urgent, and drops the time rate as any warning does.
- **The screen.** The Bore Station's tunnel panel, which showed the link, says why: "Link fast, glass tunnel  2.00 m/s", "Link 87%, 1 rough stretch  1.74 m/s", or "Link slow, through rock". The header stays TUNNEL OPEN in green: a rough tunnel is open, only dimmer. The stations recipe has the tile "Bore Station, after a Glide".
- **For the look (#127).** `tunnel_walls()` lists the tunnel behind as pieces of glass, rough or sealed wall by path distance; the view draws a glided tunnel from it.
- **A Glide home up the First dive's climb (#128).** The way down already sealed the tunnel in the granite, so the link is sound all the way home, glided or crawled, and the rough sandstone and sand change nothing for it. A rescue counts the glided climb as the crawled one: sealed through the granite, open through the sandstone and sand.


## The scan views' words and marks (#151)

Agent's choices, the developer away. Round 4's tickets each added words or marks to Navigation's three candidate scan views, and seen together they collided; nothing any view shows changed, only where its words sit and how its marks read. How it meets the code is `docs/conventions/screen-navigation.md`, "The words on the scan display".

- **A strip under the views for the tools' state.** The Sweep's line over the Beam's, each in one place in every view, below the panes rather than over them, so a tool's label never covers the scan, a scale or the expected rock's name.
  It costs the panes some 48 of the display's 209 pixels of height, about what the old labels already covered; the views keep their scales by their own rules, so they shrink a little and never turn or zoom on their own.
- **Every other word placed, never drawn blind.** Inside a pane, the title goes first, then the scale's numbers, then surface control's rock names, then a target's name; each takes the first of a few nearby places clear of the words before it and of the vessel's and aim's marks, or is left out.
  A view keeps its scale ahead of a rock's name, because a scope without its range cannot be read at all, while a rock's name moved a line further into the rock, or to the pane's left, still names the same depth.
  Where every second range ring's number would crowd, every fourth is named.
- **Words on faint backdrops**, as the rock's names already were, so the points never hide them.
- **The survey's points are small open crosses**, not hollow squares: at the size the sheet shows the screen, a hollow square read as a filled one. A cross is still the legend's grey and faint, so nothing reads as a caution.
- **Harder rock's strokes slant across the band and softer rock's dots come in staggered clusters**, drawn over the points: before, the dots lay under the points and were lost, and the strokes, straight down the band, read like the points' own smear. Slanted strokes against speckle is the geological section's own convention for hard rock and sand.
- **A target beside the rock bands.** No Scenario puts a scanned Boundary near a target: the Prospecting drill's one Boundary in reach is the granite's top, some 54 m behind the vessel and known only from the survey. The recipe's tile shows that pairing in the section; a nearer one would need a Scenario change, left for when targets get a Scenario of their own.

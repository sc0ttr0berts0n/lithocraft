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

## The Glide seen, heard and felt (#127)

Agent's choices, the developer away. How it meets the code is `docs/conventions/glide-look.md`.

- **The melt is hot rock, drawn as a hot body.** Silicate melt heated by the Head's plasma, about 1750 K at full thrust (hotter than erupting lava at 1300 to 1450 K) and 1400 K as the jet starts or dies.
  Its colour is a hot body's at that temperature, its brightness the fourth power of it (Stefan-Boltzmann), so it is yellow-white streaked with orange in a Glide, deep orange in the spin-up and spin-down.
- **It moves too fast to see.** The face is many times the Bore's area, so the melt runs aft many times faster than the vessel; at full thrust it is drawn as long streaks along the Bore, as the eye sees anything that fast, and as slow lumps while the jet builds or dies. The two crossfade with the jet's thrust, so the spin-up and spin-down are seen.
- **After the Glide it stops and crusts.** The halted slug's skin chills toward 850 K, a dull red, in some seconds (dark plates with glowing cracks between, as a lava lake's crust), while its body stays hot.
  The Column coming in at the Head end as the Crawl resumes pushes it out toward the Tail, since the melt is drawn exactly where the simulation has no Column.
- **It lights the room.** Four lights on the Bore's axis carry the melt's colour and its fourth-power brightness into the Habitat through the glass, each only where melt is beside it; the room's ambient light leans to the melt's colour, and the melt alone blooms. In a Glide the melt outshines the room's own lamps: the Habitat goes from cool grey-blue to orange.
- **The roar.** A jet's noise is broadband, its peak frequency rising with the flow's speed (the Strouhal relation) and its power steeply with it (Lighthill's eighth power), so the spin-up is a roar rising in pitch and loudness together, the spin-down the same falling to the idle's silence.
  Under it a low rumble of the hull carrying the thrust and a faint whine of the Head's power rising with the load, as a motor's does. Unlike the Crawl's juddering grind of slipping grip waves, it is steady.
- **The feel.** The jet shakes the crew a little harder than slipping grip waves at full slip, in proportion to the thrust: a steady, hard rumble rather than a judder.
- **The tunnel behind, wherever it is shown.** Glass is the plain white line it always was, a Glide's rough wall the same white drawn beaded (the developer's "lobe-like and lumpy"), sealed rock the legend's grey: on Navigation's moving map, the path behind; on the Bore Station's tunnel panel, a strip behind the Tail named glass, rough or sealed.
- **Not shown yet: a climbing Glide.** On the First dive's layout a climb's line leaves the surveyed rock before the Head lines up with an upward Course, so no Glide up can be plotted; #128's Glide home will be the first, and its recipe tile is owed then. The melt runs toward the Tail end whichever way the Habitat hangs.

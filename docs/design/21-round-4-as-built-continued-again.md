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

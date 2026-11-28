# Play test: the first full dive (28 November 2026)

The developer's First dive on the round 4 build (`dev`, the Glide and the Sweep, #159 and #161), then the Glide drill, in three recordings, narrated:

1. **7:53**, `Desktop 2026.11.28 - 11.15.40.18.mp4`: stuck on the first step of "Sand" (phase 2 of 11) and stopped. Transcript: [`transcript-1.md`](2026-11-28-first-full-dive/transcript-1.md).
2. **27:44**, `Desktop 2026.11.28 - 11.25.44.19.mp4`: the whole dive, surface to surface, paid. Transcript: [`transcript-2.md`](2026-11-28-first-full-dive/transcript-2.md).
3. **5:13**, `Desktop 2026.11.28 - 11.57.37.20.mp4`: the Glide drill, done, then free play. Transcript: [`transcript-3.md`](2026-11-28-first-full-dive/transcript-3.md).

Timestamps are `1/mm:ss`, `2/mm:ss` or `3/mm:ss` into each video. The videos will be deleted; the frames that carry the findings are kept under [Frames](#frames).

**Headline:** a success. All 11 phases were done in one sitting: down through the sandstone into the granite, target A found by Sweep and identified, the turn for home, a Glide up through the granite and the sandstone, and a crawl to the surface. "Surfaced under the Lithocraft's own power … Paid in all: 1860" (2/27:09). The Glide was the high point: "we are now going to probably use glide home, which I'm excited to do" (2/19:14), then "This is actually really cool" (2/21:44).

## What worked

- **The Glide home**, end to end: narrow the Beam, Quiet Ship, pulse the way home, plot it with M, start it, hold it on the ball (2/19:14 to 2/21:58). "This is actually really cool" (2/21:44).
- **The Glide drill**, by hand with no autopilot: plotted 300 m, flown, out at idle, standby tuned, Shift: "Love it" (3/00:16 to 3/01:42). In free play after it, a level Glide through the sandstone once pitched toward rock: "That is cool. I like that" (3/04:57).
- **Riding the Arm between screens:** "I tend to use the arm a lot, which I like. I'm looking for gameplay reasons to get off it, but it's fun" (3/00:00).
- **The Navball**, seen for the first time: "Visually, it makes a lot of sense" (1/00:25).
- **Tuning got learned.** "I'm getting good at this … because I'm getting good at it, I want it to be a little harder" (2/03:02). The Residual cancelling: "It does look satisfying when it's like the DNA double helix because you're canceling out" (2/10:32). Watching the guess tighten under pulses: "I love to see this tighten up. It is a cool visual" (2/09:24); getting the guess "for free" from the Beam's own pulsing (2/25:44).
- **Acknowledge as skip:** acknowledging the 30 s Boundary watch also lets time run on: "No problems there. I like that" (2/10:46 to 2/10:52).
- **The head/tail diagram finally read right:** "It is cool to see that the head and the tail just pass through the density" (2/04:07).
- **The Sweep found target A** dead ahead, and its region visibly narrowed: "Oh, it's getting tighter. Cute" (2/16:06).
- **The rhythm of the game:** "I'm seeing the rhythm of the game" (2/24:37). The scans already in hand at the sandstone: "That's cool that we have those scans" (2/03:40).

## Findings

### Steps that tick on a pulse, not on the key

1. **Recording 1 stalled on "Switch on the Beam's own pulsing".** The player pressed O at 1/05:28 ("pulses as it goes" shows on Navigation), then Q and P (1/05:33 to 1/05:41). The step waits for a pulse the Beam sends by itself (`scenario.gd`, `beam_pulsing`), and the Beam pulses every 15 m covered (`beam.gd`, `_PULSE_EVERY_M`). Quiet Ship then halted the vessel, so no such pulse ever came, and the Checklist stayed on step 1 of "Sand" while the quiet scan was done (frame 1/05:44). "This is not acknowledging this step or I'm doing it wrong" (1/05:44). The player asked for "a yes, I did this step" fallback (1/06:03). In recording 2, told of the 15 m, the player waited at the Drive for it (2/01:06 to 2/01:15) and asked for "next pulse, 10 m" on Navigation (2/00:52, 2/01:06).
2. **The same shape at "Narrow the Beam" (2/19:28).** Narrowed to its narrowest, the step stayed open: it ticks on a pulse at narrow width (`pulsed_at_width`). "I think I'm stuck … It wasn't clear that you had to pulse" (2/19:28 to 2/19:39).

### The Reactor

3. **The Wobble guess gives the answer away.** STANDBY prints the guess in Hz and amplitude, so tuning is copying numbers: "if I just have the answer, I might as well tune it for me" (1/02:01 to 1/02:15, again 2/02:45). Wants it "a little visual" (1/02:09, 2/02:50). The frequency steps are 2 Hz-coarse against a 1 Hz-fine guess (2/03:09).
4. **"In band if the scan is right" read as a tell.** At a 35%-sure guess, PREDICTED showed BAND while its trace looked far out of it (frame 2/08:42): "you're kind of showing your hand when you say this is in band when it doesn't visually look like it is" (2/08:55). A fresh scan then put it out of band (2/09:33).
5. **Out of the Glide, STANDBY's guess read 0.00 Hz ×0.00 at "GUESS SURE 100%"** (frame 2/22:27), and the player tuned down toward zero to match: "It's weird to be going down to zero … I'm going to assume this is a glitch" (2/22:46 to 2/23:01). The player pressed R, "things went crazy", put the old tuning back, "and then the old one just worked" (2/23:21). Not yet cross-checked in the code: whether a guess of zero is right for the Head at idle, or a guess missing for the rock round the vessel.
6. **"Shift into the sand" never ticked.** The player shifted on the count at 2/26:20; the Checklist stayed on it through the surface (frame 2/26:40), though the survey paid for 175 of sand. "Have we not shifted in the sand? … it's possible it didn't detect it" (2/26:33 to 2/26:50). Not yet cross-checked. Separately: "the skip has to be frame perfect … there probably needs to be a little window for the Shift" (2/10:57).
7. **No hold-to-repeat on tuning keys:** "I'm getting a little tired of hitting this key over and over" (2/23:38; 2/06:39).
8. **The low-power alarm is too loud for a planned halt** (Quiet Ship, out of the Glide): "needs to be way more chill" (2/20:08, 2/22:01).

### Pace

9. **Long waits, skipped with fast time.** "Still five minutes or more, huh? Might have to figure out how to make this game just overall faster" (2/09:54). Features in the sandstone and granite were waited for under fast time (2/02:23, 2/04:27, 2/12:29); the player would rather the tutorial force the first one (2/03:50).

### Screens and controls

10. **Text-line screens are wearing.** "This UI kind of stinks, because it's just text lines" (2/00:58). "That is a manual of keys" (1/01:09). Wants to click the panels (1/00:35), and an Elite-like left/right panel pair (1/01:00), folding out from the Habitat ring at the Bore Station (2/02:00 to 2/02:17).
11. **The "SANDSTONE EXPECTED" label covers the data on the forward scope** (1/03:58 to 1/04:05).
12. **Beam aim keys named left/right/down/up; wants "beam pitch, beam roll"** (1/07:09).
13. **M ("Glide plot: all the scan shows") pressed by accident, mid-dive, and M again did not undo it** (2/05:54 to 2/06:24). Middle-clicking the scan showed nothing (2/06:05).
14. **"Beyond: MUCH HARDER, DENSER 35% sure" was new and unexplained** (2/08:12 to 2/08:23).
15. **The Column view is choppy and flickers as it scrolls** (1/04:21 to 1/04:46): z-fighting or pixel-stepped movement.
16. **The Bore Station's density plot needs labelled axes** (2/04:16).
17. **The Sweep's target is hard to see on Navigation; wants it zoomable and on a right panel** (2/15:24, 2/15:52).
18. **Glide steering on WASD + QE** (W/S pitch, A/D yaw, Q/E roll) (2/21:00 to 2/21:27). The Navball's gimbal wants angle marks for the turn (2/19:05).
19. **The surface should show on Navigation**, perhaps like an airliner's weather display of land and sea (2/27:11 to 2/27:30).
20. **Mouse too sensitive; wants a sensitivity slider** (1/00:18). Station text not quite aligned (1/00:29).
21. **The Tunnel sealing warning was loud and unclear**: "Does this mean it's like my last chance to transfer data?" (2/11:05 to 2/12:19). Why the link would ever be stopped (2/13:12).

### The Glide drill (recording 3)

22. **A level Glide through the sandstone was refused: "the scan shows no rock ahead to glide"** (frame 3/04:05). Level at 400 m, with the narrow Beam reaching 941 m at Quiet Ship, Navigation read "no Boundary ahead in the scan". By design a Glide's reach is the furthest Inferred Boundary on the Course's line (`glide_reach()`, `BoundaryFit.furthest`), so uniform rock ahead, however far the Beam hears, allows none. "I didn't think we needed rock ahead to glide. I guess we do. Weird" (3/03:33 to 3/04:14). Pitched down toward the granite, it glided (3/04:47). The wording says "no rock" where it means "no Boundary".
23. **Pulses return only Boundaries, not the rock between.** Pulsing sideways, the returns sat only where the sandstone met something: "we should definitely see pulses everywhere we pulse, and it should return data for the area we've scanned, not just thresholds" (3/02:03 to 3/03:33). The dashed fit of a Boundary as it develops was liked: "kind of cool … like a technical illustration" (3/03:03). Ties to the density-palette idea below.
24. **Tuning standby by reading the guess still feels tedious:** "the answer's right in front of me … we got to get this to be fun instead of tedious" (3/01:20). Same as finding 3.
25. **Steering lives on Navigation now** (Course pitch), not the Drive, which surprised the player for a moment (3/02:03).

## The developer's ideas

- **A density palette for the scan, like a pool pH strip** (1/02:55 to 1/03:56): the scan's points coloured by density, and on hover a list of the rocks that density could be, ranked by what is likely at that depth. For prospecting: see a colour, hover, "could be sandstone, so I should go take a look". The Navigation ground report and the point cloud in one colour-coded type, like Thermal's palette (1/06:42 to 1/06:55).
- **Observing in the Column by hand** (2/07:06 to 2/07:27): instead of F, find the feature in the Column from the ring, click it to lock on and slide along with it, with Drive control there to stop and look.
- **Upload as a speed test** (2/13:24 to 2/13:51): data to send, sent, rate; paid in chunks, since a partly sent record is corrupt.
- **A fibre line left in the glass of the bore** (2/11:50 to 2/12:07, 2/13:56): a protected line paid out behind, to send light up the tube; an upgrade later.
- **W/S to move up and down the Bore** (2/01:55).
- **Project the turn** returned in spirit: the player burned heat into the Column to turn harder (2/17:29 to 2/17:57), unsure it helped (2/18:23 to 2/18:40).

## Not reached

The stranding and rescue, and the explainer. (The Glide drill, left at 2/27:36, was played in recording 3.)

## Frames

Kept in `2026-11-28-first-full-dive/frames/`, named by recording and timestamp.

| Frame | Shows | Finding |
|---|---|---|
| [1/05:44](2026-11-28-first-full-dive/frames/1-05-44-beam-pulsing-unticked.jpg) | "pulses as it goes" on, Quiet Ship, LOW POWER; the Checklist still on "Switch on the Beam's own pulsing" | 1 |
| [2/08:42](2026-11-28-first-full-dive/frames/2-08-42-in-band-if-scan-right.jpg) | GUESS SURE 35%, PREDICTED 0.01 ±0.62 marked BAND, "IN BAND IF THE SCAN IS RIGHT" | 4 |
| [2/19:28](2026-11-28-first-full-dive/frames/2-19-28-narrow-beam-unticked.jpg) | BEAM NARROW, the Checklist still on "Narrow the Beam" | 2 |
| [2/21:44](2026-11-28-first-full-dive/frames/2-21-44-glide.jpg) | The Glide on the Drive: 12.5 m/s, jet ×57, 1.7 m off line, dropping out 5 m left | What worked |
| [2/22:27](2026-11-28-first-full-dive/frames/2-22-27-idle-guess-zero.jpg) | Out of the Glide: STANDBY WOBBLE GUESS 0.00 Hz ×0.00 at GUESS SURE 100% | 5 |
| [2/23:15](2026-11-28-first-full-dive/frames/2-23-15-after-the-idle-shift.jpg) | After the Shift at idle: ACTIVE in band, STANDBY's counter-wave left at 0.25 Hz ×0.00 | 5 |
| [2/26:40](2026-11-28-first-full-dive/frames/2-26-40-shift-into-sand-unticked.jpg) | After the last Boundary, the Checklist still on "Shift into the sand" | 6 |
| [2/27:09](2026-11-28-first-full-dive/frames/2-27-09-paid.jpg) | Surfaced and paid: 1860 | Headline |
| [3/04:05](2026-11-28-first-full-dive/frames/3-04-05-no-rock-ahead-to-glide.jpg) | Level in the sandstone, Beam reach 941 m: "no Boundary ahead", "no rock ahead to glide" | 22 |

# Failure, hull wear, death and rescue

## Failure

- Stranding is the usual failure: sealed in, plasma out, running on the emergency store.
  It is recoverable at a price (a rescue, a relight, a restart from the last port).
  It does not delete the save.
- Hull failure is death, with a rebuy; see the next section.

## Hull wear, death and rescue

Grilled with the developer on 25 November 2026.
Before this, heat sent outward wore the hull but wear did nothing, so protecting the Column cost nothing (stories 19, 21 and 23 were hollow).

- **The developer's model is Elite Dangerous heat.**
  Zero hull is death; unmanaged heat brings hull damage, and how far over the limit sets how fast the hull declines.
  Telegraphing is juice, as in Elite near a star or under silent running.
- **Damage curve (Elite plus creep).**
  Below the hull's rated temperature, no damage.
  Above it, integrity falls at a rate set by how far over, multiplied by depth (pressure is the stress that drives creep).
  Real basis: creep is negligible below a material's temperature limit and accelerates steeply above it and with stress.
- **Lingering deep heats the hull.**
  Hot surrounding rock conducts heat in at any power, so careful means efficient, not slow.
  This answers the developer's worry that impatient players kill themselves: a careful dive is not a slow one.
  Better ships later make today's unviable depths and pressures reachable.
  In the first dive (2 km) the rock never wears an idle hull; lingering starts to bite on deeper dives, and the first dive teaches heat routing (confirmed by the developer).
- **Wear is permanent within a dive** and repaired at the surface.
  Surfacing deducts a repair bill proportional to wear, shown in the payment breakdown.
  Later the Fabricator may print hull patches, their quality set by the waveform match.
- **Telegraphing.**
  The hull groans as it creeps, louder and more often with wear and stress, heard around the ring.
  Sparks and screen shake while damage is actively happening.
  The Thermal screen shows wear and creep rate.
  No markers on the view.
- **Hull failure is death with an Elite-style rebuy.**
  All unsold data is lost and a rebuy is paid; the save is kept.
  The first dive has no saved money yet, so death ends the dive with the rebuy shown as a line in the breakdown, charged once a balance exists.
- **A worn Head.**
  No wear by running hours ("repair is repair").
  A worn Head delivers less power, narrows the Shift window and grades it harsher, and at high wear a poor Shift can lose the plasma.
  Head repair is a line in the repair bill.
  *Superseded in part by "The Reactor cancels the rock's wobble" (After the second checkpoint): there is no Shift window or grade; wear narrows the Band.*
- **Losing the plasma loses main power.**
  The developer asked whether the Head, being the fusion generator, drops to a backup.
  Real basis: a tokamak cannot restart itself; striking a plasma takes a large pulse of stored energy from outside (JET drew its pulses from huge flywheel generators, not the grid).
- **One emergency store** (the developer loved this) is the backup power once the plasma is lost.
  Uploading survey data, cooling, and a relight all draw on it, so every choice while stranded spends the same store.
- **Relighting the Head.**
  The Reactor can try: it costs a big pulse from the store.
  Success ends the stranding and the dive goes on; failure spends the energy.
  A healthy Head almost always relights; the odds fall with Head wear.
- **Built (#26, 25 November 2026).**
  The store is full at the start of each dive and untouched while the plasma holds; a relight is a pulse of about two fifths of it, so the store buys two tries or an hour or so of the slow link, not both.
  Choices the implementation made, open to the developer:
  - A stranding keeps the survey aboard so the link can still send it on the store; the recovery (a stand-in for rescue until #21) loses what is left.
    Before, stranding lost it at once.
  - The Bore Station can stop the link (B), so the store can be saved for a relight.
  - A poor Shift on a badly worn Head can disrupt the plasma without wearing the Head through: the Head keeps only the wear that Shift did, and the relight rolls at that real wear (from about nine in ten on a fresh Head down to about two in five on one worn through).
    Wearing the Head through still loses the plasma.
    The Reactor screen shows the odds on the Head as it is.
    A clean Shift wears nothing, so even a relit Head worn through holds through clean ones and is lost again to any poor one.
  - Relight gets its own Reactor key (I), not R, so a Shift pressed as the plasma goes cannot spend the store.
  - While stranded the time rate may be raised although the Reactor calls: the crew wait on the link and the store.
- **The stranding clock (the developer's idea)** is the time to hull failure as heat from the surrounding rock soaks in with the Head dark.
  Its length depends on the rock's heat (depth), the hull's wear, and battery spent on cooling.
- **Rescue time** is a fast run down the open tunnel plus a slow cut through the sealed length behind the Lithocraft.
  The Thermal screen shows the clock as a live estimate beside the rescue time, so rescue or death can be read at a glance.
- **Rescue brings the data home.**
  Unsent data is lost only on death, so uploading is insurance for when the clock is shorter than the rescue time.
  Rescue costs a line in the payment breakdown, scaled by how long it took.
  It sits between a clean surfacing and a rebuy.
- **Built (#21, 25 November 2026).**
  Choices the implementation made, open to the developer:
  - What soaks in is the melt the Head left round the vessel and in the sealed tunnel behind, a fixed margin (about 300 K) above the surrounding rock.
    Real basis: a melt front sits near the rock's melting point, far hotter than the far rock, and with the Head dark no pumps carry its heat away.
    The rock alone (300 to 400 K in the first dive) is far below the hull's rated 600 K, so it could never fail the hull.
    Deeper, the rock is hotter and presses harder, so the clock is shorter; a worn hull has less left to lose.
    Confirmed by the developer: the melt is the source, and a shallow dive staying safe is just how it is.
  - The clock is worked out exactly from the same soak and creep rules the hull follows, so the time shown is the time the hull fails if nothing changes.
    In cool shallow rock it can be hours; in hot or deep rock, minutes.
  - Cooling is the Thermal Station's heat split (C / V), which while stranded sets how hard the pumps carry the soaked heat into the Column on the store.
    The pumps stop with the Head (the split drops to 0 at the stranding), so spending the store on cooling is the crew's choice, never automatic.
    No new key.
  - The rescue is called at the stranding and arrives on its own after the rescue time: a run down the open tunnel at about 5 m/s plus a cut through the sealed length at about 0.2 m/s, about 0.4 pay per second of it.
    Enter no longer calls a recovery; the crew can relight, wait (time can run fast while stranded), or die.
    In the first dive the tunnel seals only in granite, so a stranding a hundred metres into the granite is a near race and a deep one usually needs cooling or insurance.
  - The rescue bills the rescue line and the hull and Head repairs, as surfacing does, and sells everything aboard.
    **A dive's pay never goes below 0 (developer, 25 November 2026):** whatever the rescue and repairs cost beyond what the dive earned is "on us" when they save you.
    The game models no debt for no reason.
  - Once sealed in, the Thermal screen shows the clock and the rescue time as "if stranded" estimates while under way, so the crew can judge the risk before it happens.
- **Time pressures are tracked, not felt, in the first dive.**
  Fuel burned, the rock creeping shut, and a contract clock are measured and described but have no effect yet.
- **Self-destruct by overheating (developer's idea, 25 November 2026).**
  Asked whether a stranded crew should be able to give up, the developer chose agency over a skip button: "self destruct is at least cool and gives the player agency. overheating is the way to go."
  - **Self-destruct is the vessel mismanaging itself on purpose.**
    Under way, the in-system way to make immense heat already exists: the Reactor at full power with Thermal sending all heat outward.
    Self-destruct sets exactly that and takes the Stations off the crew.
    Stranded, with the Head dark, the only energy aboard is the emergency store, so self-destruct dumps it into the hull as heat (real basis: stored electrical energy discharged through a resistive load all becomes heat).
  - **It is armed by holding a key for three seconds**, with the groans rising while held.
    It is not a one-way door: the crew can cancel it while it runs, keeping whatever wear (or store) it has already spent.
  - **Death by self-destruct** is its own cause of death, named as such, with the same price as any death: unsent data lost and the rebuy line shown.
- **A numpad debug menu (developer's idea, 25 November 2026).**
  Numpad minus opens a visual debug menu that draws the rest of the numpad with what each key does written out.
  Anything useful for testing goes there (the developer: "anything you dream up goes there"), with F3's overlay folded in.
- **Keys are stated plainly on screen for now (25 November 2026).**
  Ultimately the Stations will be widgets, levers and knobs; until then each Station's screen clearly says which keys do what, using key prompt images from Xelu's free prompts (CC0, thoseawesomeguys.com/prompts).
  The added Station keys (relight, the link, cooling while stranded, fast time while stranded) stay ordinary crew controls; the debug menu holds only testing shortcuts.
- **Quiet Ship stands as designed.**
  The developer likes it: it halts and idles so the picture sharpens, at the cost of time and shuttered survey stretches.

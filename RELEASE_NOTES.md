# Voxel Ascendant 3.0.58 — gatehouses, glass exits and volcano fixes

- Restores modern gatehouse exteriors: fractional sliding-glass geometry no longer produces empty leaves that reject the entire building model. Checked on Routes 2, 5, 6, 7, 8, 11, 12, 15, 16 and 18.
- Glass exits in supported window-enabled rooms now continue the same exterior view as adjacent windows, without squeezing a second miniature street scene into the door. Reuses the existing exterior rendering.
- Selects the authored Cinnabar lava battle terrarium for KASC's verified Blaine volcano arena.
- Adds native-footprint 3D stairs to the scripted volcano route. Turning STAIRS off retains the original closed foundation.
- Seats the Hoenn visitor on her actual chair; floor fallback positions remain standing.
- Rival spectator-duel Pokémon follow the selected follower appearance, with live style switching and restoration when disabled.

Update together with **KASC 6.7.31**. Replace the existing mods; keep saves and settings. Complete public 3.0.57 baseline and assets retained.

25 targeted suites and native desktop checks passed. Optional HD/MMO replacement is covered by fixtures; the native visual check used Cobblemon. Physical mobile hardware and a broad performance benchmark were not rerun. See the attached QA report for scope and remaining uncertainties.

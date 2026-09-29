# Voxel Ascendant 3.0.55

Fixes getting stuck on Game Corner stools: leaving a seat returns the player to a free adjacent aisle, including after a minigame or restoration has lost the transient sitting state. Neighboring chairs remain solid; occupied exits are never used.

The shared loading intro runs after New Game or Continue, once when both mods are enabled. Pikachu/Eevee animation now advances with presented frames instead of skipping through the sequence after a loading stall. Required preparation stays covered until ready; the native introduction and save-validation prompts retain their ownership.

Update the existing mod through the launcher, or import this complete ZIP as an update, then restart. Do not create a second mod with the same ID. Existing saves and options are retained; no new game is needed. No separate startup-preview mod is required.

This release includes the prepared integration changes:

- Reuses validated wardrobe images across launches and recognizes Continue in older Recompiler versions, reducing repeated character setup during loading.
- Covered rooftop arrivals wait for rendered surroundings. Generated rooftop/lookout scenery has a bounded, versioned disk cache; incompatible entries rebuild normally.
- Cooperative weather-mask preparation and prewarmed Silph fountain animation reduce measured loading spikes. Yellow receives matching window captures and domestic bitmaps.
- DISCS keeps the original Pokémon disk size, places trainers behind them on separate small patches, and uses closer framing, Terrarium zoom steps, a 180-degree manual orbit and fixed HP cards. Cobblemon size handling corrects oversized-wing-envelope shrinkage such as Charizard.
- Integrated weather and character-provider adapters are retained. HD human assets are separated from the base package: Voxel/Cobble remain available, and HD requires the optional character DLC. Existing external character-card installations remain supported.
- Gen 2 offers original move animations through the native battle presentation; explicit model selections clear stale sprite overrides. AUTO trainer art respects engine-delivered player replacements.

Tests and limits are documented in QA-REPORT.md. This update reduces specific measured stalls; it does not promise constant 60 FPS or eliminate every first-use load. Physical iPhone/Switch performance is not certified by the desktop tests.

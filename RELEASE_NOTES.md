# Voxel Ascendant 3.0.61-rc.6 — hotel reception correction

The Prismania/Celadon hotel receptionist remains on her native floor cell behind the reception desk. A scoped depth-bias correction lets the opaque counter hide her legs instead of drawing them over the tabletop. Native position, floor height, collision and across-counter dialogue are preserved. The guard checks the original hotel and exact counter tiles; other rooms, moving actors and changed layouts retain their existing draw behavior.

Voxel and Cobble pass four native camera angles and dialogue. Four focused regressions pass. The shared sitter recognition covers all twelve current placements: eleven Pokémon Centers and this hotel; hotel Voxel/Cobble/OFF rendering additionally checked. Builds on the complete rc.5 candidate. Physical mobile and optional HD-pack scene acceptance remain open; no public release.

---

# Voxel Ascendant 3.0.61-rc.5 — local completion

Replaces the tile-authored Center sitter with separate Voxel-HD and Cobble artwork. Cobble follows the existing roster/Bedrock rig and transparent export workflow, including eye/lid blinking. The temporary hand-built substitute was discarded. Fixed cushion anchor and walking OFF fallback are retained; three Centers per style verified. HD retains its existing source when its optional pack is available.

The Voxel Silph glass lift uses a quiet, fading motor loop instead of repeated collision SFX, keeping the arrival chime and native sounds for other lifts/glass OFF. Native ride and focused checks pass. All 30 registered outfit recipes are now distinct from original in each of HD, Voxel, Cobble and 2D. The actual bedroom south window was captured unobstructed. Eight focused regressions pass. See QA-REPORT.md and the full video audit for evidence and limitations; physical iPhone/iPad acceptance remains open. No public release.

---

# Voxel Ascendant 3.0.61-rc.4 — local follow-up

Fixes vertically mirrored Mew choice/prompt and binocular help on the iOS final composite. Focused regressions and native iOS policy landscape/portrait wish flow pass. Prepared mobile sky already existed; physical device acceptance remains open. Review identifies the old Center sitter in Voxel/Cobble, verifies 30 distinct HD outfit recipes and visible animated Nidoking send-out, and narrows the Silph sound to the lift's 100 Collision triggers pending listening. Full evidence and limitations: QA-REPORT.md and docs/VIDEO_FEEDBACK_20260930.md. No public release.

---

# Voxel Ascendant 3.0.61-rc.3 — local video polish candidate

This candidate builds on 3.0.61-rc.2. That base already contains the loading/language fix, Cobble cyclists and older-card seat compatibility; those are retained, not newly implemented here. Public release remains 3.0.60.

- Larger, wrapping English/German binocular instructions, composed after world blur.
- Larger Safari ball counter and action labels.
- Compact, shallower Museum/Tower/Rocket flights with unchanged native routes.
- Three large lab scrolls on one wall in native starter-ball order: Charmander, Squirtle, Bulbasaur. Scrolls lowered, excess wall height reduced, bookcases unchanged. Uses the existing artwork.
- More recognizable museum orbiter and small Cerulean Gym floor/wall refinements.
- Temporary dinner plates, soup, cutlery and cups after Mother's native heal.
- Separate Mewtwo constellation. Rare six-second, world-projected Mew star outline at night; timely A while looking towards it opens a small window over the sky. Choose one Nugget, Elixir or Ultra Ball per appearance. No Master Ball reward. Native interactions retain priority; cancel/full-bag/reload behavior protected.
- Updates the obsolete window-landmark test stub to the current existing API.

23 regression checks and targeted native desktop interaction/rendering/save-load checks passed. Physical mobile testing remains open; the follow-up rc.4 review confirms staged mobile sky is already available. No public release or installed-game update performed. The additional volcano extension is excluded: the existing KASC volcano already covers the user's request.

---

# Voxel Ascendant 3.0.60 — Pyro MAP battle and Sea Terrarium

- Pyro/Blaine's volcano MAP battle now places both Pokémon on the central Pokéball marking, with the trainers just outside it. The camera leaves the surrounding lava visible.
- The suspended platform remains visible during MAP battles, and four cached lava fountains animate outside the court.
- Adds ODias' Sea Terrarium with a submerged reef, separate Pokémon shelves and trainer pillars, transparent animated water, original credits and both camera perspectives.
- Sea scenery applies to surfing encounters on Routes 12, 13, 19, 20, 21, Pallet Town, Cinnabar Island and Vermilion City. Land, inland water, interiors, Gen 2 and fishing from land retain their existing scenes.
- Includes all public 3.0.59 changes, including the Gorochu Crystal colour fix. No changes to Pokémon stats, abilities or battle rules.

**Update together with [KASC 6.7.32](https://github.com/Roxas2712/kanto-ascendant/releases/tag/v6.7.32)** for the narrower platform. Replace the existing mod copies and keep saves/settings.

Promoted from the tested 3.0.60-rc.1 candidate with identical runtime code and assets. Native desktop battles, both Sea cameras, moves/attack rendering, GL/GLES shader validation, Lua syntax, archive CRC and file-hash checks passed. Physical mobile devices were not tested; the portrait touch preview is a layout check.

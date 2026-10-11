# Source exterior sky and day/night conventions

Seven authenticated ferry quays and `TrainerTower_Roof` retained their source `outdoor=false` metadata, although the admitted presentation recipe correctly identified them as exterior. Weather used that recipe; `HorizonWall.hasSky` used the raw metadata. At NIGHT the quay/roof therefore kept neutral tint and the indoor shadow rig, while native Kanto dock/ship/roofs used open-air sky and lighting.

`hasSky` now uses the same admitted exterior recipe for Sevii. A canopy closes the sky as in Viridian Forest. Existing `SilphWindows` ownership retains precedence: 31 actual admitted window rooms still expose their window sky; their world renderer keeps the existing separate room-light/window convention. Source definitions, map/save/flag IDs, collision, geometry and weather are unchanged. No per-frame table or new asset is introduced.

## Reproduce and repeat

Use paired KASC 6.7.33-rc.17-sevii with VASC 3.0.63-rc.16-sevii (before) or rc.17-sevii (after), gen1recomp 0.3.61 / `7ac15ebbf78b298344e15db72406ff37e94099f6`, LOVE 11.5. On `KA_SEVII_HARBOR` at cell (5,3), choose voxel camera 1, SCENERY FULL, NIGHT, WEATHER CLEAR and dynamic lights ON/OFF. Before, night tint is `[1,1,1]`; after it follows the same pinned Kanto night tint. All eight locations and exact coordinates are in the native receipts.

Run `tests/sevii_sky_conventions_test.lua` with the repository LOVE test harness. It checks all 266 source-family sky rules, the seven source-indoor quays and roof, and existing open-air/closed Kanto references. Run `tests/sevii_sky_conventions_native.lua` through the engine's private QA driver loader. Supply `SEVII_KASC_ROOT` for the gameplay fixture and `HABITAT_QA_ROOT` for receipts; isolated QA identity must match `vasc-sevii-…-qa`. Use `SEVII_SKY_FIXED=1` after the fix. `SEVII_SKY_CAMERA=0` captures 2D; default 1 captures voxel. Use a ROM you legally supply, never commit it or a player save. Actual ZIP SHA/source receipts are required; a worktree overlay alone is not packaged evidence.

## Evidence and limits

`tests/evidence/sevii-sky-conventions-20261008/proof.json` indexes four completed native ZIP fixtures. Each resolves all 266 actual atlas-admitted families and captures 44 frames: seven quays, roof, three Kanto open-air references, DAY/NIGHT × local lights ON/OFF. Source sky mismatches reduce from 8 to 0. Canopy/window and six-mode weather resolution are unchanged across all 266 maps (1,596 API queries per fixture). These are API weather checks; rain/snow rendering and all presets/camera angles are outside this scope.

All 44 before/after 2D frames, 12 extra Kanto light/day frames and 16 standard Kanto reference images are full-RGBA pixel-identical, with no masks or tolerance. The standard after capture is fresh and uses the exact frozen driver of the completed RC17/RC16 baseline. All 59 Sevii component tests pass; 1,917 engine source files remain unchanged. VASC ZIP changes consist solely of `lib/HorizonWall.lua` and version metadata. KASC ZIP remains immutable.

Prepared champion/teleport state, fixed clocks and stationary NPCs make these presentation checks reproducible. They do not replace the documented historical continuous story runs, complete geometry/seam/visibility audit or original Android/Adreno 830 reproduction. The full master objective remains open.

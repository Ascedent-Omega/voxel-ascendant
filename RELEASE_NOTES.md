# Voxel Ascendant 3.0.59 — Gorochu Crystal colour fix

Fixes a remaining case where Gorochu stayed monochrome despite selecting **Crystal** battle graphics. KASC's modern battle rules keep a separate battle-only stats table for split Special Attack and Special Defense. VASC mistakenly treated that table as evidence of Transform and skipped the selected sprite.

- Crystal and HD selections now survive ordinary battle-stat copies, including HD preloading.
- Native Transform, explicit transformation flags, Mega and ghost presentation retain their existing ownership.
- Pokémon stats, abilities, battle rules and saves are unchanged. All VASC 3.0.58 gatehouse, door, volcano and visitor fixes remain included.

**Only update VASC. KASC 6.7.31 remains the companion version.** Keep saves and settings; replace the existing mod rather than enabling a second copy.

The failure was reproduced in native LOVE with Gorochu versus Starmie and KASC's real split-Special preparation. The corrected path returns the coloured sprite; native Transform still works. Focused Crystal/HD front/back and normal/shiny tests, settings regressions, 1,340 Lua syntax checks, archive CRC and file receipts passed. No new physical mobile-device test was performed. Runtime and assets are unchanged from the tested 3.0.59-rc.1 candidate.

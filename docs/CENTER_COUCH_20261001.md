# Voxel Ascendant 3.0.62-rc.2 — upholstered Center couch

Replaces the shared native couch extrusion with an authored blue upholstered voxel sofa: two seat/back cushions, stepped armrests and recessed feet. Exact full drawing recognition covers eleven Pokémon Centers and Celadon Hotel. Native collision and the 8px seat anchor remain unchanged. Furniture ownership explicitly preserves only the original seated man; other overlapping figures keep their existing protection. Furniture OFF restores native terrain; walking-sprite OFF keeps the original seated-person art on the new couch.

Builds on the complete 3.0.62-rc.1 online merge. Fourteen focused regressions pass. Native LÖVE census identifies all twelve placements, with HD/Voxel/Cobble rendering in Viridian Center and Celadon Hotel, plus both OFF fallbacks. The packaged candidate is checked again independently before delivery. Physical mobile testing, subjective lift listening and a human HD in-game download catalog remain open. Local candidate; no public release.

---

QA artifacts: /Users/maarten/Documents/Recompile/artifacts/vasc-couch-20261001. Native integration driver: tests/drivers/center_couch.lua. Unit ownership/anchor test: tests/center_couch_figure_test.lua. Furniture claim changes only visual terrain state; raw map cells, objects and scripts remain untouched. New palette entries append after existing colors to retain all previous indices.

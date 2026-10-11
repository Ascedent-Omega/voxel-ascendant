# Paired RC14 / RC9 source animation proof

This cause follows the retained RC13/RC8 static-import diagnostic. The original source animation callbacks are now authenticated and exported; native 2D streams and VASC GPU/foreground presentation both consume that contract. Existing maps, non-animation tileset data and static PNG bytes match the baseline.

- Independent source replay: 7,227 distinct visible states and 58 foreground underlays, with original two-layer compositing, flips and palettes.
- Actual packaged native 2D output: 266 maps, 135 animated tilesets, 3,176 streams, 36,443 claimed slots and 59,716 exact decoded pixel samples.
- Actual packaged VASC proof: 135 preparations/evictions, 2,896 surface streams, 43 foreground streams / 185 source cells and 768 exact GPU canvas comparisons. Three complete 640-tick cycles reject any new GPU or pixel-buffer allocation after preparation. Each owned buffer/mesh is released on eviction; borrowed native images remain usable.
- Real world before/after captures: Four Island flowers (20,9), Ember Spa steam (14,9), Kindle coast (14,34), at native ticks 17/49, both 2D and voxel. Before retains the preceding static bundle with all other fixes; after loads the final RC14/RC9 ZIPs. Captures are direct and unedited.
- Exact packaged Kanto proof: all 16 full RGBA images match the retained baseline, without crop, mask or tolerance. Deterministic clocks/actors/RNG and matched isolated Viridian/Cinnabar initialization are unchanged.
- 54 Sevii component checks pass; the separate cache ownership budget contract also passes. All 1,917 engine source hashes remain unchanged.

`native-markers.json`, completed measurement JSON and sanitized execution receipts identify the actual ZIP hashes and Lua hashes. `map-animation-fix-current.json` summarizes the source/native checks, exact maps and preserved fields. Generated frame PNGs, ROM, saves and raw logs are excluded. The private release ZIPs retain the derived animation assets.

`superseded-fixture.json` retains the rejected unsupported LÖVE isReleased probe. `superseded-kanto-options-fixture.json` records an initially mismatched seeded options profile; current comparisons use the baseline gbc options. `superseded-map-entries.json` retains three disconnected-plot door-selection failures; the corrected driver selects a reachable authored exit or reciprocal seam. The final 266-map receipt reports 253 physical entry/exits and 13 no-incoming-edge scenery fragments. None of these fixture corrections changes production collision or masks a pixel difference.

Engine gen1recomp 0.3.61 / commit 7ac15ebbf78b298344e15db72406ff37e94099f6, LÖVE 11.5 / macOS. Android Adreno 830 D11, mobile materials/FPS, the specific Groudon wing/provider state and missing authentic follower artwork remain open. Main-story/optional proofs retain their prior explicit fixtures; this change does not claim a fresh complete resource-balance journey or every camera angle.

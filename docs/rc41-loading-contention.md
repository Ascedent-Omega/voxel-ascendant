# RC41 — stop rendering an invisible finished world during Continue

## Final change

Continue first restores the save, prepares the destination, and proves a complete scene was presented. While the opaque Continue cover then prepares the remaining region, reuse that scene canvas instead of repeatedly rendering the hidden world. Update, region preparation, input ownership and the loading indicator continue normally. No extra canvas is allocated. Reuse ends when the cover is removed, another state becomes topmost, the map/viewport changes, or scene readiness is invalidated. The first visible frame is rendered normally. The cover holds its own borrowed canvas; the module only weakly references the cover.

VoxelPropBatch also retains the discovered template counts while an immutable furniture receipt is still being prepared. It re-enumerates on receipt, map or callback changes and discards the temporary snapshot at completion/clear. Geometry and draw paths are unchanged.

This narrow change is in the Gen 1 desktop rendering path. It does not establish a Gen 2 or mobile improvement and does not yet apply this loading optimization to gate/cave transitions.

## Native measurements

Artifacts: `/Users/maarten/Documents/Recompile/artifacts/performance-prop-upload-20260928`.
Isolated muted `vasc-video-polish-qa` identity; actual title Continue callback; 1710×958, balanced resolution, Voxel 6, tilt shift 3, Voxel buildings and real windows enabled, night/rain. The A/B switch only disables reuse of the hidden scene. Timings include diagnostic wrappers and are observations, not universal FPS promises.

| Scene | Continue without reuse | With reuse | Hidden full scenes avoided |
|---|---:|---:|---:|
| Silph Co 1F | 21.62 s | 11.87 s | 596 |
| Saffron City | 13.83 s | 10.49 s | 326 |

Silph repeats measured 21.31 s before / 11.87 s after. In the final Silph pair, covered CPU time totaled about 12.01 s / 4.24 s; covered scene-render time 3.02 s / 0.067 s. The maximum measured graphics mesh constructor during covered frames went from 23.75 ms to 1.44 ms. This supports avoiding contention with repeated invisible rendering; it does not prove the old delay was solely Lua table conversion or GPU execution.

Both Silph runs prepared the same twelve terrain/atlas maps, retained three panoramas, and stopped optional scenery at the existing memory/build admission limit. Both city runs prepared thirteen terrain/atlas maps, with four optional route panoramas skipped for partial neighbourhoods and the existing scenery admission limit retained. City baseline had a static-light disk-cache hit while the after run built that field; these are not perfectly identical cold-cache benchmarks. All admission/readiness assertions passed. Arrival screenshots were inspected with buildings and windows still present.

Post-reveal camera sweeps do **not** establish an FPS gain: final Silph A/B averaged 59.0 / 54.6 FPS (max frames 33.4 / 49.9 ms); Saffron 55.1 / 54.7 FPS (max 34.5 / 33.6 ms). An earlier reuse run averaged 57.2 FPS. These results leave visible frame stability open. Save restoration still has long covered frames. The older direct-teleport 430 ms fixture bypassed the actual Continue cover and is not evidence of a normal uncovered Continue frame.

## Verification

- `continue_preparation_test.lua`: indicator before restoration, exactly-once restore, readiness plus presentation proof, region completion, Vanilla/non-Continue behavior, no stale reuse across invalidation/map/viewport/top-state changes, immediate normal rendering after removal.
- `prop_prewarm_test.lua`: incomplete immutable discovery only once, changed receipt, separate color/shadow, distant/seasonal props, shared frame budget and non-instanced fallback.
- `region_preparation_test.lua` and `region_plan_test.lua`: existing cache admission, shared queue, boundaries, indoor maps, cancellation and warm-hit contracts.
- Native `rc41_continue.lua`: actual Continue plus 240-frame indoor and 360-frame city camera sweeps, complete destination and region assertions; logs/traces/results and loading/arrival screenshots retained.
- Native `rc41_prop_upload.lua`: six before/after cases (768, 6000, 19998 vertices; indexed/unindexed), GPU vertex/index hashes and rendered instanced color/shadow hashes must match, five instances each; discovery only once in final implementation. See `pairs-final` for final code.

An experimental binary upload change was removed after isolated timings failed to show a consistent gain. `SceneryMeshUpload.lua` and its test were restored exactly to their pre-turn contents. The retained implementation changes only three production files. No asset rebuild, visual-quality reduction, commit or release is part of this checkpoint.

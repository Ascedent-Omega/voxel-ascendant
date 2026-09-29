# RC40 — large actor image stalls and first-use mist shaders

This checkpoint targets measured preparation spikes. It does not establish smooth performance across all maps or devices.

## Changes

- The scene's admitted full Voxel human atlases now use the existing bounded PNG worker during actor preparation. Native 16×96 fallback strips and unrelated images retain their existing asset path. Only one decoder is active, with a 16 MiB decoded-image admission limit for these sheets. The main thread uploads the decoded pixels once; the scene owns and releases that texture. No second engine-cache copy is created by this path.
- Bounds admission runs once for a pending job, not again on every poll. The verified bounds accompany the upload. Map changes, superseded preparation and renderer detachment cancel pending work. Unsupported workers and failed decodes retain the synchronous fallback. Ordinary unprepared draw calls retain the old fallback rather than starting an orphaned background job.
- Gen 2 now exposes the same exact worker and resolves its two modules at the package root. This also makes the pre-existing optional decoder seam available to its integrated card renderer.
- Gen 1's relevant mist shader is compiled in the existing update preparation queue. The lit path no longer also compiles the unused plain shader. Failures are terminal until invalidation, and the mist effect fails closed. GLSL, density, lighting, resolution and compositing are unchanged. Gen 2 does not use this IndoorMist rendering path.

## Verification

- `human_atlas_preload_test.lua`: pending/busy handling, no duplicate synchronous loading while pending, no repeated PNG bounds hash, ownership and release on upload failure, cancellation, unsupported/failed worker fallback and untouched foreign assets.
- `indoor_mist_prewarm_test.lua`: preparation before the room's light frame exists, selected variant once, dark/unrelated maps, failure termination and retry after invalidation.
- Native `rc40_atlas_pixels.lua`: four actual 1152×1536 atlases, full rendered GPU pixel hashes equal to direct PNG loading in both generations. Decoder completion count confirms worker use. Worker CPU time is not counted as main-thread time. The first cold bounds catalog still costs about 26–33 ms; subsequent complete preparation steps measured about 7–12 ms. These are not FPS measurements and the reference is loaded after the worker, so driver-cache order can affect timings.
- Gen 2 New Bark Town smoke test: 170 successful 3D renders, no lighting failure, screenshot inspected. This is not a broad Gen 2 performance benchmark.
- Existing native mist composite regression passes: 2504 checked pixels, maximum error 0.000257. An initial attempt with the headless Lua runner was invalid because this test requires native LOVE graphics; it was rerun in the native driver successfully.
- Saffron → Silph 1F → 6F → Saffron → 1F → Saffron, full Voxel buildings enabled, real windows, nighttime/rain, Voxel 6, tilt shift 3, balanced resolution, 1710×958. Before: full actor PNG calls 20.8–28.1 ms. Final atlas-only run: twelve corresponding pixel uploads 1.74–2.62 ms; no synchronous full actor PNG loads. The eyelid sheet still loads synchronously (~9.5 ms). All runs completed, visuals retained; Saffron screenshot inspected.
- After mist preparation, its slow shader call is in `main_gen1.update` before the first full interior render, not `IndoorMist.draw`. The focused first-frame probe confirms the same placement.

## Crucial limits / next highest priority

The full test does NOT show a reliable overall FPS improvement. Maxima and percentiles vary across runs; some percentiles got worse. Atlas-only baseline/final maxima: Saffron 80.46/74.35 ms, Silph 1F 61.83/79.68 ms, 6F 50.70/44.64 ms. These include direct map-install preparation, not a real Continue/door-transition UI benchmark.

The subsequent `with-mist` run captured a 430.45 ms CPU frame on the first full Silph 1F draw (frame 920): 419.78 ms inside scene rendering, including 86.29 ms LightVisibility.prepare. The remaining time is not adequately attributed and must not be called GPU time. A focused repeat with graphics-call instrumentation did not reproduce that extreme: first full Silph frame 53.11 ms, including 4.50 ms visibility preparation. This does NOT prove the original cold-frame spike is fixed. Keep this as a primary open issue.

Repeated expensive prop-batch mesh construction is independently visible in the focused trace (`VoxelPropBatch` → `Voxel3D.newMesh`, 15–20 ms individual native allocations), along with first-frame prop resolution. These and cold lighting/first-draw work are the next concrete targets. No blanket 60 FPS or mobile/Switch performance claim is justified.

Artifacts: `/Users/maarten/Documents/Recompile/artifacts/performance-human-atlas-20260928`.
All QA used the muted isolated `vasc-video-polish-qa` identity. No user saves, personal options or release builds were changed. No native QA process remains active.

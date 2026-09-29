# RC39 — measured Silph preparation stalls

Scope: targeted fixes to synchronous scene preparation; no reduction in Voxel buildings, window detail, weather, lighting or scene geometry.

## Fixes

1. Kanto `extended_characters.installRivalPresentation` previously called the battle arena preflight on every map entry even when the normal and standing rival portraits resolve to the identical runtime path. That unnecessarily constructed map structures and furniture GPU geometry in an event callback. Identical paths now bypass that decision. Distinct paths still use the original capability/staging predicate. Trainer identity, color and restoration baseline are unchanged.
2. `SilphWindows.build` now forwards the existing scheduling callback to CinnabarVolcano. Nearby window geometry also yields during box generation and bounds calculation and uses the existing staged scenery uploader. The Horizon job owns completed window/landmark meshes while construction is suspended, allowing cleanup on cancellation/failure. Output order and geometry are preserved.

The first volcano-only change did NOT remove the large full-scene spike. The follow-up trace identified the nearby box loop between flushes as another unsliced region. The final change includes both. This distinction matters: neither a local microbenchmark nor a first guess was accepted as the final result.

## Validation and measurement

- `rival_portrait_fast_path_test.lua` compares baseline/current actual function bodies: equal paths with staging true/false, distinct paths with true/false, repeated calls, saved restoration state, identity and color. Equal paths no longer probe the arena; different paths retain the decision.
- `silph_window_scheduling_test.lua`: callback forwarding, parent ownership while suspended and after simulated upload failure, no duplicated landmark, preserved offset/class.
- Existing volcano scheduling and scenery upload tests pass.
- Native `rc39_window_slices.lua` compares actual complete baseline/current window builds for Silph 1F and 6F. Every GPU vertex and vertex index, mesh order and landmark metadata hashes identically. Largest coroutine step: 45.80 → 8.25 ms (1F), 29.27 → 6.28 ms (6F). Reference runs first, so these isolated timings can include driver/cache order effects; exact output equality is separately asserted.
- Native `rc39_silph_stress.lua`: Saffron → Silph 1F → 6F → Saffron → 1F → Saffron, camera rotations, full Voxel buildings explicitly enabled, real windows enabled, night/rain, Voxel 6, tilt shift 3, balanced resolution, 1710×958. Both runs finish. This fixture installs maps directly and includes their preparation, not real warp/Continue UI timing.
- In that full trace, Silph 6F window/horizon preparation maximum: 116.00 → 9.78 ms. Rival presentation in 1F: 84.89 → 0.028 ms. Largest measured CPU update+draw per map: 1F 122.06 → 64.77 ms; 6F 127.62 → 50.50 ms. Runtime spawns and resource warming vary, so these are observed maxima, not a universal FPS percentage improvement.
- The baseline's initial Saffron setup also spent 1166.86 ms in the redundant portrait preflight (frame 0). This is setup latency, not a measured normal gameplay frame or an end-to-end Continue improvement.
- Before/after 6F screenshots inspected: window view and Vulkan remain present. The stronger visual invariant is the exact geometry/index comparison; weather/cloud time differs between screenshots.

All native processes used the muted isolated `vasc-video-polish-qa` identity and have exited. No personal saves/options or release artifacts were altered.

## Still open

The overall performance goal is NOT complete. Saffron's early preparation still shows a 90.61 ms CPU frame, including 41.52 ms image allocation/39.02 ms Assets.image (nested measurements, not additive). Shader first use and light grid work remain visible peaks. Actual gameplay reports of 4–10 FPS have not been reproduced or ruled out across all maps/devices. No 60 FPS guarantee follows from these fixes.

Artifacts: `/Users/maarten/Documents/Recompile/artifacts/performance-saffron-critical-20260928` (before, intermediate profiles, final, paired geometry results, comparison.json and rollback checkpoint).

# RC43 — Stop redrawing an already-ready scene during native region loading

Primo 1 native building/gate region preparation continued rendering the complete arrival on every frame while an opaque transition waited for future maps. RC41 avoided this during Continue only. The native region wait now borrows the already-presented scene canvas after its region job exists. Update and cache preparation keep running. No new framebuffer or image copy is introduced.

The borrowed frame is valid only for the same overworld, map object, opaque transition object and render dimensions, with `VoxelScene.readyForReveal` still true. Readiness loss, resize, a new cover, fade or gameplay invalidates reuse. Completed/cancelled/replaced transitions discard their frame with their job. The mobile rendering branch does not use this optimization. Production settings, textures, buildings, shaders, cache budgets and region membership remain unchanged.

## Native A/B

Artifacts: `/Users/maarten/Documents/Recompile/artifacts/performance-transition-spikes-20260928`.

`tests/native/rc43_transitions.lua` uses the muted isolated QA identity, actual native warp/reveal hooks, Voxel buildings and real windows enabled, rain, night, first person, 1710×958, balanced render resolution, 512 MB residency. A warm-up native arrival is followed by entry to Silph 1F, an internal 2F warp, and exit to Saffron. All eleven floors plus elevator must have terrain/aux/atlas ready; an internal warp must not repeat region preparation. `QA_DISABLE_REGION_HOLD=1` disables only the new reuse path for the reference.

| Metric | ab-before | ab-after |
| --- | ---: | ---: |
| Silph entry | 11.302 s | 6.517 s |
| Silph cover frames | 782 | 714 |
| Hidden scene draws avoided, whole run | 0 | 943 |
| CPU time across covered frames, whole run | 26.444 s | 12.068 s |
| Draw callback across covered frames | 12.516 s | 2.739 s |
| Scene render across covered frames | 10.399 s | 1.249 s |

Both runs exited 0 with PASS_RC43_TRANSITIONS and the same 12 prepared building maps, no skipped maps, and the same optional scenery-memory-or-build limit. These are sequential same-machine measurements, not guaranteed timings on other hardware. Covered totals include startup, entry, floor and exit waits. Frame-count differences and cache warmth can affect totals; this is not a pure GPU timing comparison.

No gameplay-FPS improvement is claimed. The first-person city screenshot ended facing a solid surface, so its post-exit camera sweep is not representative evidence of open-city performance. The indoor screenshot does show the voxel scene. A separate third-person run also exited 0 (6.384 s entry, 932 reuses), but its city capture remained a solid yellow field with weather visible. This occurs in the unmodified reference as well and is not established as a wall versus another existing scene/camera defect. Its city FPS figures are also rejected as representative performance evidence. Investigate this fixture/scene defect before using it for open-city FPS comparisons.

## Validation and unresolved work

Headless tests pass: `region_scene_hold_test.lua` (all ownership/readiness/resize/fade/cancellation guards), `region_preparation_test.lua`, `region_plan_test.lua`, and `continue_preparation_test.lua`.

Early diagnostic runs did not pass: the direct-teleport fixture did not satisfy the native reveal contract; an earlier exit assertion also assumed a literal destination rather than resolving the return-map warp. Those logs remain in the artifact directory. The final fixture uses native arrival and resolved destinations.

The initial trace found a 62 ms LocalLightGrid preparation during an uncovered route change. This observation narrows further investigation but does not establish its exact subcomponent or fix it. The reported 4 FPS cases remain unverified and unresolved. This change removes a confirmed source of contention during loading; it is not a claim that Primo 1 or Primo 2 performance is complete.

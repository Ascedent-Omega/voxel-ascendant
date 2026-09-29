# RC45: stage light index texture construction

`LocalLightGrid` already divided cell selection across frames, but filled the entire CPU index image synchronously at completion. It now continues the same preparation job through index-image construction, checking the shared budget every 32 populated cells. Covered preparation retains its existing 4 ms allowance and visible preparation its 0.75 ms allowance. Standalone consumers still complete synchronously.

Only a completed image is uploaded and published. The pending job owns its CPU ImageData; OFF, map/geometry replacement, explicit cancellation, reset and coroutine errors release unfinished data. A failed GPU upload releases the completed CPU image before propagating the error. The previous complete grid remains available during same-map preparation; another map never receives its coordinates. Existing scene readiness checks keep loading coverage while the grid is pending.

This does not impose a hard frame-time ceiling. Allocation, hashing, GC, source grouping/sorting, visibility construction and GPU work remain indivisible. The GPU representation, light count, blockers and visual settings are unchanged.

## Evidence

Artifacts: `/Users/maarten/Documents/Recompile/artifacts/performance-light-plan-20260929`.

- `index-test/run.log`: staged indices, source-data and visibility textures have exactly the same rendered bytes as the preceding synchronous implementation. Static-light cache identity also matches. Cancellation specifically during pixel filling releases the private CPU image without changing the active GPU texture.
- `staged-equivalence/run.log`: existing native visibility reuse and 72-light checks pass, including mobile limits, distant occlusion, flicker, OFF/reset, same-map atomic publication and new-map staging.
- Headless checks: shared Gen-2 paths, facade instances, bounded selection and lighting failure isolation pass.
- `before` and `staged-after`: same native Celadon–Route 7–Celadon–Route 16–Celadon walking fixture, full Voxel buildings, night/rain, first person, 1710×958, isolated muted QA identity. Both complete successfully. Setup through frame 400, covered frames and QA pathfinding plus the following delta frame are excluded.

| CPU measurement | Reference | Changed |
| --- | ---: | ---: |
| Largest light completion call (calls reaching visibility preparation) | 29.61 ms | 14.83 ms |
| Largest light preparation call, any phase | 29.61 ms | 27.28 ms |
| CPU frame p95 | 24.17 ms | 17.91 ms |
| Frames above 33.33 ms | 17 / 2621 | 4 / 2377 |
| Worst CPU frame | 55.53 ms | 78.99 ms |

These are one pair of runs with different timing/sample counts, not proof of a global FPS target. The worse single-frame maximum is explicitly retained in the report. Source grouping and map-entered work remain problems. No 4 FPS reproduction has been obtained.

An earlier spatial blocker search experiment (`after`, `equivalence`, archived `light_blocker_index_test.lua`) preserved exact results but produced no reliable native benefit. It was reverted; `LightVisibility.lua` is byte-identical to this artifact's source-before copy. It is not part of the shipped change or claimed gain.

No user-save changes, release or commit.

# RC44: divide actor model decoding across preparation steps

The native Celadon → Route 7 → Celadon → Route 16 → Celadon walk reproduced visible loading stalls. In the reference run, an actor prewarm call occupied 44.16 ms (41.35 ms inside model record loading). This change gives the existing actor prewarm lane a cooperative 1.5 ms decoding budget. Direct battle/provider loads retain their synchronous API.

Binary parsing checkpoints every 128 nodes and each numeric-vector chunk. Suspended models remain private until complete; actor readiness requires the completed record and texture. A removed actor, appearance/content epoch change, or destination-map change discards the pending job. Gen 2 delegates to the same shared pack implementation. No geometry, textures, lighting, or building options are reduced.

The budget is not a hard wall-clock bound: file reads, hashing, zlib decompression, JSON fallback, metrics, GPU uploads, GC, and scheduling can still exceed it. Those operations were not made asynchronous by this change.

## Native comparison

Artifacts: `/Users/maarten/Documents/Recompile/artifacts/performance-city-frame-20260928` (`walk`, `walk-after`, `comparison.json`). Both runs completed the actual walking route using `tests/native/rc34_light_travel.lua`, full Voxel buildings, night/rain, first-person camera, 1710×958, and isolated muted QA identity. Excluded setup through frame 400, covered frames, and the QA pathfinder frame plus its following delta frame.

| Observed measurement | Reference | Changed |
| --- | ---: | ---: |
| Maximum actor prewarm call | 44.16 ms | 2.48 ms |
| CPU frame p95 | 25.29 ms | 19.49 ms |
| Frames exceeding 33.33 ms | 26 / 2679 | 7 / 2406 |
| Maximum CPU frame | 82.53 ms | 82.00 ms |

This is one pair of runs, not a hardware-independent FPS claim. Different timing changes actor movement and sample counts. The bounded prewarm call is the directly targeted result; aggregate improvements cannot all be attributed to this change. Trace timers around a coroutine-spanning record call do not represent one frame's CPU time; use the per-call `prewarmEntities` slices instead.

Remaining stalls include local-light preparation, map-entered work, terrain GPU uploads and GC. The reported 4 FPS case has not been reproduced. The initial Silph-exit screenshot was also diagnosed as a camera inside the exterior facade, so it is not used as a valid city benchmark.

## Checks

- `cobblemon_actor_preload_test.lua`: existing exact-record leases, optional failures and readiness.
- `cobblemon_cooperative_preload_test.lua`: slicing, no repeated restart, atomic readiness, cancellation on removed actor/variant/map/content epoch.
- `cobblemon_residency_test.lua`: bounded residency, GC reuse, LRU, texture accounting.
- `cobblemon_failure_lifecycle_test.lua`: failures, recovery and GPU ownership.
- `tests/native/rc44_model_decode.lua`: compare cooperative and synchronous binary output against original JSON for the bundled catalog; retain malformed-input checks. Native output is stored in `decode/run.log` and `decode/decode.json`.

Native catalog validation passed for all 1,069 records: cooperative output equals synchronous binary and original JSON values; 4,922 slices were exercised. The catalog stress run recorded a maximum slice of 39.51 ms, confirming that this is a soft decode budget, not a hard frame-time guarantee (decompression/GC/OS scheduling are not preempted). The gameplay route measured a maximum prewarm call of 2.48 ms.

No release, user-save mutation or commit is part of this checkpoint.

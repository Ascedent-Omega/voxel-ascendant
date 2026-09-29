# Render budget investigation — 2026-09-28

The initial investigation below led to the implemented follow-up documented
at the end of this file. Effects remain enabled in the shipped renderer.

## Evidence

Native LOVE 11.5, QA identity only, muted audio, night and rain, moving player
and rotating camera, 128 MiB terrain residency budget (not total RAM).
VSync was disabled to expose available throughput. The resolution comparison
uses 1,200 frames per city and fixed render sizes rather than AUTO scaling.

| City | Render size | Average FPS | p95 ms | p99 ms | Maximum ms |
| --- | --- | ---: | ---: | ---: | ---: |
| Saffron | 1710 × 955 | 53.53 | 27.91 | 32.09 | 48.87 |
| Saffron | 1280 × 715 | 71.87 | 19.56 | 24.75 | 60.59 |
| Celadon | 1710 × 955 | 46.76 | 30.35 | 32.58 | 61.00 |
| Celadon | 1280 × 715 | 52.26 | 27.59 | 42.96 | 71.91 |

Saffron's timed update/draw CPU work was almost unchanged between resolutions:
1.453/4.517 ms versus 1.369/4.558 ms. Pixel workload is therefore a credible
additional bottleneck. Celadon's worse tail at lower resolution also shows
that reducing pixel count does not solve all stalls. These are single runs,
not a hardware qualification or a guarantee of repeatable gains.

A separate 900-frame-per-variant Saffron diagnostic at 1710 × 955 measured:

| Variant | Average FPS | p95 ms | p99 ms |
| --- | ---: | ---: | ---: |
| Lighting on, tilt shift 3 | 47.46 | 28.78 | 35.24 |
| Lighting off, tilt shift 3 | 113.42 | 13.88 | 16.98 |
| Lighting on, tilt shift off | 39.42 | 33.75 | 43.43 |

The lighting toggle controls the broader local/dynamic lighting path; this
does not isolate a single shader or prove that caching one part yields the
entire gain. Variants ran sequentially, so warmup, thermal state, scene
animation and variable movement timing remain confounders. The blur-off
result does not support claiming a blur optimization gain. Actual GPU
timestamp measurements were not collected. CPU submission timers cannot
separate driver stalls, presentation and GPU execution.

An intrusive horizon/mesh diagnostic was excluded from the FPS comparison.
It did not confirm `setVertices` as the cause of an earlier 25 ms batch-draw
spike. A speculative buffer replacement was reverted before acceptance.

Raw results are under:
`/Users/maarten/Documents/Recompile/artifacts/vasc-rc19-lookouts/octopath-comparison/`
(`fixed.log`, `720-clean.log`, `effects.log`, and per-run `results.json`).

## What the Octopath comparison establishes

Acquire explicitly describes a fixed exploration camera, mostly 3D
backgrounds, 2D characters, dynamic day/night lighting and per-platform
quality tuning. This is not evidence that all backgrounds are photographs
or that all of Octopath's lighting is baked:

https://www.unrealengine.com/developer-interviews/octopath-traveler-ii-builds-a-bigger-bolder-world-in-its-stunning-hd-2d-style

Our free camera and first-person mode require geometry to work from more
directions. That increases the need for view-dependent visibility and
distance detail. Static lighting as a mobile optimization is documented
separately by Epic; it is a proposed technique for this renderer, not a
claim about Octopath's internal implementation:

https://dev.epicgames.com/documentation/unreal-engine/performance-guidelines-for-mobile-devices-in-unreal-engine

## Implementation order and acceptance gates

1. Prototype cached stationary illumination in one representative city.
   `LocalLightGrid` currently caches light selection and occlusion data but
   still shades visible fragments against local lights each frame. Cache
   diffuse illumination on stationary surfaces; retain dynamic character
   lighting, changing sources and view-dependent water reflections. Cover
   all voxel face normals and height layers, and preserve wall occlusion.
   Treat day/night weights, window states and geometry versions as explicit
   invalidation inputs. Build under the existing loading cover and persist
   versioned results. Compare equal-resolution on/off screenshots and frame
   distributions before expanding coverage.
2. Finish preparing GPU batch templates before revealing a region. Terrain
   disk caching and shader preparation already exist. `VoxelPropBatch`
   still clones source vertices and creates per-pass meshes on first use.
   Prepare only the region's expected source meshes in bounded slices;
   account for CPU and GPU copies in the residency budget. Exercise a full
   camera turn after reveal, not only the initial facing direction.
3. Reduce distant scene cost without losing landmarks. Preserve the volcano
   and skyline silhouettes while using simpler distant building/tree
   geometry. Existing instancing and frustum culling must be extended, not
   added a second time. Ordinary-house bitmap windows and large-window
   hybrid views remain appropriate separate cases.
4. Revisit expensive effect resolutions only after isolated measurement.
   Keep UI and the sharp image region crisp; avoid assuming that every
   effect needs full-resolution intermediate buffers. The current blur
   diagnostic is inconclusive and does not justify a production change.

Loading and continuous rendering require separate budgets. A disk cache
reduces construction and IO work; it cannot eliminate per-frame lighting.
For a 60 Hz mode, target roughly 12–14 ms typical work to leave headroom,
then evaluate p95/p99, worst frames and repeated cold/warm transitions.
Repeat measurements on actual target devices before promising a mode.
Lower-memory devices need bounded resident regions rather than loading all
maps at startup. Retain cave/gate region boundaries and large-building
preparation; ordinary houses remain part of their surrounding region.

## Implemented follow-up

The stationary facade-light field and arrival batch preparation are now
implemented. The earlier evidence and proposal above remain the record of
why these paths were selected; they are not a claim that every remaining
render bottleneck is solved.

`StaticLightField` bakes diffuse facade illumination for six axis-aligned
normals and fourteen height samples (-8 through 96 world units). Horizontal
sampling adapts from 4 to at most 16 units to respect texture limits and a
16 MiB desktop / 8 MiB mobile cap per field. One completed field and one
replacement can coexist during preparation. Unstable bake inputs debounce
for 150 ms after a cancelled build, preserving the dynamic fallback without
repeated texture allocation or a stuck loading cover. Higher/sloped surfaces, actors,
water reflections, cave masks and nonstationary sources retain the original
lighting path. A normalized field can follow a shared day/night lamp-strength
change without rebuilding. Changed source classes, geometry, colors or
blockers invalidate it. Publication is atomic; failed optional allocations
retain normal dynamic lighting.

Dynamic-light membership is stored per grid cell so a torch elsewhere does
not cause redundant per-pixel evaluation on every cached surface.

The field shader is prepared in the existing update/loading lane. Baking is
limited to six face/layer slices per covered frame and one during play.
`StaticLightDiskCache` persists versioned LZ4-compressed RGBA pixels in sixteen
fixed slots, each capped at 16 MiB plus its header. Keys cover source code,
light/occluder geometry, source membership, selected light indices and field
resolution. Canonical light and blocker ordering permits reuse when connected
maps finish in a different order. Declared decompressed length, dimensions,
key and pixel checksum are checked before accepting cache data. Disk IO and
GPU readback happen only under loading cover.

`VoxelPropBatch.prewarm` visits the full arrival view before camera culling,
prepares color/shadow templates and instance capacities, and slices vertex
copying into a bounded update budget. Seasonal blossom groups are included.
The reveal gate now also checks this preparation and pending irradiance work.
No map topology, collision, voxel asset style, weather setting, water setting,
render resolution or distant landmark visibility was reduced by this change.

### Validation

Artifacts:
`/Users/maarten/Documents/Recompile/artifacts/vasc-rc19-lookouts/static-light-field/`

- Native GPU probe: six normals, height samples, thin-wall occlusion,
  source-order independence, shared power scaling, dynamic-source changes,
  actors/water/sloped/high-surface fallback, blocker invalidation, abandoned
  replacement cancellation, 20 unstable input frames with only one allocation
  followed by successful settled rebuild, OFF/reset, rejected optional allocation, and
  bounded dimensions. Maximum sampled lattice difference was 3/255 in the
  red channel; the tested wall's extra leakage was zero. This is sampled QA,
  not proof of identical pixels at every interpolated position.
- Native disk roundtrip plus malformed declared-length rejection. Separate
  process restart: first run one write / zero hits, restart one hit / zero
  writes / zero bakes. Observed Continue cover was 4.56 s versus 4.02 s;
  these single samples are not a general load-time percentage claim.
- Native Continue completed with 78 prewarmed template/stream groups. Route 7
  gate crossings passed in both directions with a 128 MiB terrain budget.
- Headless regressions passed for bounded light selection, facade reuse,
  lighting allocation failure isolation, water preload, region preparation,
  gate prefetch and sliced batch prewarm. The batch test verifies that the
  first color/shadow draw creates no new warmed templates, including blossom
  palette groups. Existing 72-light native staging/visibility tests passed.
- Fixed 1710 × 955, night/rain, lights on, tilt shift 3, 900 moving/rotating
  frames per variant. Compare reference to the *repeated* cache run, after
  both scenes reached the same source count and sampled player positions:

| City | Reference FPS | Cached FPS | Reference p95 | Cached p95 | Reference p99 | Cached p99 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Saffron (478 sources) | 44.93 | 55.53 | 29.56 ms | 22.95 ms | 42.81 ms | 33.16 ms |
| Celadon (313 sources) | 35.34 | 41.85 | 40.12 ms | 31.30 ms | 47.71 ms | 41.90 ms |

The first cache runs had smaller prepared scene unions and are not used as
matched improvement claims. Screenshots were visually compared; lighting,
facade appearance and silhouettes remain recognizable, with interpolation
rather than pixel-identical output. The first comparison improved average FPS about 24% / 19%, but occasional
stalls remain. A subsequent full run (`final-comparison.log`) reproduced
Saffron's benefit (46.37 → 55.92 FPS; p99 38.15 → 24.41 ms), while Celadon
reversed (41.05 → 36.80 FPS; p99 36.73 → 41.52 ms). Celadon therefore does
not yet support a reliable general speedup claim; the repeated checks below
record the observed spread instead of selecting only favorable samples. The 198 ms reference outlier
included first-use water work during scene expansion and is not presented as
an irradiance-cache speedup. Constant 60 FPS and iPhone/Switch qualification
remain unproven. Distant-geometry LOD and lower-resolution effect passes were
not changed without independent visual/performance validation.


A final fresh-process Celadon recheck (`celadon-recheck.log`) alternated the
same renderer switch five times. The initial cache warmup had 294 sources
and is excluded. The remaining four samples each had 313 sources and the
same recorded player positions:

| Sequence | FPS | p95 | p99 |
| --- | ---: | ---: | ---: |
| Reference | 30.25 | 46.97 ms | 52.30 ms |
| Cache repeat | 32.57 | 40.55 ms | 45.99 ms |
| Reference repeat | 25.64 | 54.20 ms | 66.37 ms |
| Cache final | 32.27 | 40.70 ms | 49.28 ms |

This confirms substantial run-to-run variation even in the unchanged
reference. Only one native LOVE process was present. No cause such as
thermal throttling is asserted without measurement. The cache benefits
these adjacent comparisons, but the earlier reversal is retained above;
there is no universal percentage or constant-frame-rate claim.

Final checks: `latest-fixture.log` passed the dynamic-cell and allocation
settling additions; all seven scoped headless regression files passed;
scoped whitespace checks passed. `implementation.patch` records the four
production-file deltas against this turn's backups and the newly added
cache/prewarm fixture files, without unrelated working-tree changes.

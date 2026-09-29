# RC42 — Gen 2 SKY water was still drawing world reflections

Gen 2 `VoxelScene.drawWater` called the full framebuffer-copy/actor-paint path even when WATER was set to SKY. The water fragment shader sets `rays=0` for that setting and never samples the scene reflection. This was repeated work every rendered frame.

The SKY call now passes the ordinary water atlas as the unused reflection sampler. `Voxel3D.beginWater` detaches the existing depth texture for the unchanged manual fragment depth test, without allocating/copying a mirror canvas or drawing the reflected cast. `endWater` retains its normal shader/depth restoration. A failed target bind restores the depth attachment. Missing texture falls back to the full path. FULL, OFF and the mobile flat-water path are unchanged. The user's water setting is not changed by production code. No shader, mesh, image, resolution or lighting change is included.

## Evidence

Artifact root: `/Users/maarten/Documents/Recompile/artifacts/performance-water-visibility-20260928`.
Native Crystal / Cherrygrove City, third person, 1710×958, isolated muted `vasc-video-polish-qa`. `rc42_sky_water.lua` performs alternating old/new/old/new 240-frame camera sweeps separately for SKY and FULL, using the same live scene. The reference disables only the new optional SKY texture argument.

In `sky-final`, aggregated 480-frame samples per side:

- SKY water CPU call time: **1.307 → 0.088 ms/frame**.
- SKY whole-scene CPU call time: **3.836 → 3.300 ms/frame**.
- Reflected cast draws in SKY: **480 → 0**.
- FULL still drew 480 reflected casts on both sides. Its timings varied; no FULL improvement is claimed.

These instrumented CPU-call timings include any waits inside the calls; they are not GPU timers or an overall FPS improvement claim. They do not establish smooth performance across either game. Primo 1's active-gameplay spikes and the reported 4 FPS cases remain unresolved by this change.

`gen2_sky_water_test.lua` executes the actual production function with graphics stubs: no SKY allocation/copy/cast, detached readable depth, existing FULL allocation reuse, failed binding recovery and inactive/missing-depth fallbacks.

The initial offscreen-water experiments did not eliminate a single reflection in the tested coastal scene, even with tighter spatial bounds. No such culling change was shipped. The diagnostic script is retained only in the artifact directory.

The in-frame pixel-comparison diagnostic is inconclusive: after fixing its Canvas lookup, its unchanged-reference versus unchanged-reference control also produced different hashes. No pixel-equivalence claim is made. Failed diagnostic runs and the diagnostic script are retained in the artifact directory, not installed as passing regression tests. The shipped native test measures the real render path and asserts SKY/FULL cast counts; it does not claim exact pixel equivalence.

Final rerun (`final`): headless contract test passed; native driver exited 0 with `PASS_GEN2_WATER`, 480 SKY cast draws reduced to 0, and FULL retained 480. SKY water CPU time was 1.697 → 0.065 ms/frame in this rerun. Existing missing submerged follower assets logged fallback retries at entry; no renderer-overlay failure occurred. End-of-sweep screenshot was inspected, but is not an exact image-equivalence test.

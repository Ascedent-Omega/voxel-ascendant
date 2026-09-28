# VASC 3.0.53 — Mobile shadow hotfix verification

2026-09-28. Public hotfix base: VASC 3.0.52 (`9d1f02c9`). Local 3.0.53-rc.* features are excluded. No save, native collision, story or model-asset changes.

## GPU and renderer checks
- Real Metal (LÖVE 12) and OpenGL (LÖVE 11.5) on Apple M2, using iOS and Android platform receipts: Gen 1 and Gen 2 production shadow writers pass depth rejection, packed-depth readback and orientation calibration. Metal requires flipped texture Y; OpenGL does not. Desktop retains its projection path.
- Explicit 512px colour/depth attachments; complete caller state restored with an existing nested colour/depth target, scissor and transform. Finish, abort and injected caster failure exercised. Failed device admission is latched for the session.
- Production Gen 1 receivers compile with/without dynamic lighting: compact core, shadows, shadows plus aerial effects, full desktop and desktop fallback. Real rendered pixels change from fully lit to approximately 60% brightness under shadow; presentation-card reception OFF remains lit. Local-lighting OFF retains shadows.
- 24 linked GLSL/GLES programs (48 shader stages), including Gen 2 lit/unlit receivers, pass the Khronos validator. The production writers also compile and draw natively on both backends. The strict GLES check caught a Gen 2 cross-stage camera-uniform precision mismatch; both declarations are now explicitly highp.

## Complete game checks
- Isolated native test host, engine 0.3.2, separate QA identities. Gen 1 Alabastia and Gen 2 New Bark Town: shadow map activates; ON/OFF/ON transitions and landscape/portrait rendering pass under both iOS/Metal and Android/OpenGL test paths. Screenshots inspected.
- Tests use the production mod loader and its sandbox. The player's running game and saves were not changed.
- The Gen 2 QA fixture overlays its existing generated Crystal artwork into the legacy host's fallback asset location; no such artwork is added to the mod package.

## Failure and regression tests
14 targeted suites pass: device_shadows_failure, shadow_resource_lifecycle, gen2_platform_receipt, gen2_mobile_render_policy, mobile_depth_attachment, mobile_world_streaming, mobile_terrain_queue, mobile_diagnostic_budget, lighting_failure_isolation, arena_sky_mobile, terrarium_light_reuse, terrarium_effect_failure, terrarium_zoom, mod_setting_fallback.

Failure injection covers renderer queries, colour/depth allocation, shader link, GPU draw, readback, invalid pixels and a caster/provider exception. Temporary resources are released, graphics state restored and repeat attempts suppressed. The resource-lifecycle test includes 600 stable availability checks and explicit invalidation.

## Package checks and limits
Complete ZIP, Lua syntax, CRC, source-byte equality and both embedded hash receipts are checked by the release builder. See the accompanying verification.json for exact counts and SHA-256.

No physical iPhone/Android, device-model performance certification, full game playthrough or FPS guarantee is claimed. A real GPU driver hang/process termination is outside Lua exception recovery. The on-device startup test gates correctness and target support, not sustained thermal performance. SHADOWS OFF remains available. Rollback: public VASC 3.0.52.

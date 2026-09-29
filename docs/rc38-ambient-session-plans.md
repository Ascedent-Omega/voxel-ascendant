# RC38 — stable ambient town Pokémon

The bundled Kanto ambient NPC manager now keeps a private, seeded placement plan per session and map. Town density is 1–2. Authored NPCs, combat encounter RNG, and the Gen2 authored-map exclusion are unchanged. Indoor density remains unchanged.

Plans retain species, idle/wander choice and spawn coordinates. Reentry reuses them after checking current collision and occupancy. Invalid coordinates receive a deterministic repair search; if there is no safe site, the actor is omitted. A session changes when the game/save object changes. The cache holds at most 64 recently used maps, only small metadata, no map/model references. Evicted plans regenerate deterministic choices, but coordinates may differ with the entry position. This is a session cache, not a save-file or disk-cache change.

Placement and wandering reject map boundaries, water, doors, counters, warps/stair warps and their immediate approaches. A bounded local connectivity proof rejects choke points rather than allowing an ambient actor to sever a walkable passage. Temporarily occupied branches remain part of the proof. Current positions and reserved movement targets are checked. Two ambient Pokémon must have at least one tile between them, including diagonally. The same guard runs before each wandering step. It cannot control later movement of the player or unrelated authored NPCs.

No global RNG is reseeded. The initial session seed is drawn once; subsequent plan choices use a private stream. Normal NPC construction/idle animation still uses engine randomness. No visual settings or geometry were downgraded.

## Verification

- Headless `tests/ambient_plan_test.lua`: 100 seeds, both density outcomes, stable reentries without another candidate search, independent plan RNG, narrow corridors, warp approaches, boundaries, diagonal separation, moving reservations, terrain/NPC changes, no-space omission, cache bound and save replacement.
- Existing `tests/wilds_empty_map_retry_test.lua` passes.
- Native LOVE `tests/native/rc38_ambient_plans.lua`: actual maps and NPC construction for all ten Kanto towns/cities; 100 returns preserve species/positions/behavior without fresh position searches. 20,000 per-city simulation ticks exercise real ambient wandering and verify active movement targets.
- Isolated, muted `vasc-video-polish-qa` identity. This is a logic/placement test, not a visual FPS benchmark. Artifacts: `artifacts/performance-ambient-plans-20260928/native-verified`.

The optimization bounds visible ambient actors and prevents new species/placement churn on repeated visits. It does not fix every renderer stall, future combat spawn, shader compile or GPU upload, and supplies no universal 60 FPS guarantee.

# Pyro and door implementation

`BlaineVolcano` models only the three exact KASC-owned maps. Arena geometry versions 1 and 2 are checked against their known platform and bridge rectangles. Static meshes and one shader-animated lava surface are prepared before claims become visible. Native foundation tiles remain beneath the basalt so the scene's atomic reveal retains a real terrain mesh. The open arena bypasses the cave flood mask; ordinary caves keep it. Ember placement retreats into blocked native rock cells. Weather, mist and lights reuse the existing Lavados paths, with bounded ash and no particle accumulation.

The compact native floor is owned by the companion KASC worktree, not patched into game data by VASC. VASC's custom models do not edit collision, events, warps, quiz scripts or rewards. The dedicated actor catalogue includes the old and new Blaine positions.

`Gen1GlassDoors` discovers matching native outdoor/interior profiles, excludes Pallet wood and rooftop/upper-floor stair destinations, and records reciprocal sources. Gate views distinguish outgoing destinations and incoming warp indices. Route 22's position-dependent LAST_MAP exits have distinct keys. Exterior adjacent warp cells are merged into one doorway. Pallet's interior panels carry explicit single-leaf metadata.

Door audio is prepared with the scene. Existing meshes move by matrix translation. Opaque closed panes suppress hidden destination-image draws inside and outside; visible pictures retain their original resolution and day tint. The native transition wrapper still preserves its arguments, return values and error cleanup.

Reproduction tools: `tools/qa_glass_door_views.lua`, `tools/qa_blaine_doors.lua`, `tools/qa_glass_door_performance.lua`. Use only an isolated native host and disposable POKEPORT_IDENTITY. Set VASC_DOOR_ASSETS for picture generation or VASC_PERF_DIR for acceptance/performance artifacts. See QA-REPORT.md for measured results and limits.

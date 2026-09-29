# Weather.6 — shallow drifts, footprints and walkable snow banks

User feedback: normal/deep looked identical; deep snow must stay ankle-high, preserve Pokemon visibility, leave tracks and turn settled snow over native jump ledges into walkable ramps.

## Behavior

- Deep snow uses 2/3/4 world-pixel tiers at full buildup. Coverage follows the visible foreground between eye and focus, capped and quantized, instead of concentrating around the distant look-at point. One retained mesh; max 8,405 quads. Snow remains cosmetic outside the explicit native ledge ramps.
- Battle snow is a continuous four-voxel level surface at full buildup, with no combatant cutouts or camera corridors. Pokemon, battle heroes and Johto live-world trainers use the same quantized buildup height as the mesh, including thaw. Actor/battle collision rules remain unchanged.
- Settled deep snow hides native outdoor flower geometry and its shadows. Flower/grass cells retain their walkable ground beneath the snow, eliminating the old square holes. Roof and water exclusions remain intact. Flowers return as snow thaws or NORMAL is selected.
- Player boot impressions alternate left/right, have separate heel/toe rectangles, and follow the actual snow surface. They fade over 55 seconds with a 64-print bound, in one retained draw. Tracking is independent of SFX volume. No footprints while jumping, surfing/cycling, across teleports, on water/roofed ground, or in flat/disabled snow mode. Map changes clear the trail.
- Settled deep snow at amount >= .65 bridges small native outdoor jump ledges; thaw begins below .45. Both Kanto and Johto movement owners permit walking uphill and downhill without the original hop. A player occupying a melting bank can finish crossing before it disappears. Native collision data remains unchanged.
- Ramps only join already connected, ordinary walkable regions across an authored jump ledge with <= 6 world pixels of height difference. Water, map boundaries, warps, occupied cells and arbitrary cliffs are excluded. Mountain paths containing eligible ledges work by the same rule; this does not turn all mountain walls into traversable terrain.

## Validation

Pure Lua: snow tiers and bounds, continuous battle coverage and matching actor height during buildup/thaw; flower burial with roof exclusions, ledge approach exclusion, tracks including mute/expiry/teleport/hop/roof cases, and both ramp adapters (ascent/descent, entity and side entry veto, foot support, thaw retention).

Native macOS LOVE runtime: Red and Crystal overworld snow, fixed-camera normal/deep comparison, tracks rendered with production shaders, native battle views, full/mobile GL and GLES compile checks. Actual `Player:tryMove` / `World:movePlayer` calls walked both directions onto snow banks on ROUTE_1 (32 eligible banks) and ROUTE_29 (36 eligible banks), with no jumping flag. Native scripts deliberately advance weather buildup. No physical mobile/VR performance measurement.

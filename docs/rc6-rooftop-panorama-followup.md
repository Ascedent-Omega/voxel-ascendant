# Rooftop and panorama follow-up

## Implemented

`RooftopFly` scopes the native outside-map check to synchronous FLY validation on six exact Gen 1 voxel terrace profiles. It does not change persistent map metadata. The native Party menu, native WorldAPI and KASC's public Field Kit map-policy provider retain their existing badge, party and destination behavior. Bindings are restored even on errors. Other field moves and 2D are unchanged.

`LoadingCompanion` coalesces warp/stream probes for one map. Previously their alternating kinds reset the debounce every frame, keeping the upstairs loading indicator hidden. Cover ownership stays with the warp; readiness still releases immediately.

VASC rain was already enabled on the open lookout profiles. Native Route 12 acceptance verifies precipitation and absence of roof cover; no speculative weather patch was added.

## Panorama reports (rc.7 follow-up below)

- Lavender: facing north, right of the Pokémon Tower, missing panorama.
- Route 13: missing panorama in the direction of Silph Co. The landmark is the reference, not a due-north heading.
- Both user screenshots: 3.0.57-rc.5.
- Awaiting the user's game basis and PC MAP RING / OUTDOOR HORIZON options. Fresh native Gen 1 test views did not reproduce the specific voids. Preserve the reports as open; no claimed fix or arbitrary scenery replacement.

Evidence: `artifacts/voxel-rooftop-lavender-20260930` in the parent workspace. Native diagnostic scripts change only isolated QA identities. A diagnostic camera uses radians for the corrected precise views. Earlier scan scripts passed degrees to a radians field and are not exact-view acceptance evidence.

## rc.7: local evidence and coastal ownership

The user's latest native session and matching actor log establish Red/Gen 1 and rc.5. Saved options establish PC MAP RING on, OUTDOOR HORIZON voxel, V-CURVE 1 and local terrain heights. These were available under the live `Application Support/pokemon-love2d` identity, outside the isolated `LOVE` QA identities.

Using that configuration reproduces the Route 13 gap toward Silph. The panorama builder let a neighbour's diagonal sea policy veto an aligned land strip. Direct land-edge ownership now wins over diagonal coastal extension; actual perpendicular sea strips still veto terrain. Ground shoulders and canopy placement share the rule. A regression test fails against rc.6 and passes with the fix, including Lavender/Route 12 and negative coastline/body/connection cases.

Route 13 is visually reproduced and fixed. Lavender's related east-edge exclusion is fixed, with native directional comparisons, but the exact submitted Lavender screenshot remains unmatched. No further settings question is pending.

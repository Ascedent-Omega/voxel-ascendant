# Original Kanto mist conventions on imported Sevii maps

The imported Sevii presentation previously selected a separate four-family
mist table. Its caves used density 0.010 instead of Kanto's 0.015, canopy maps
used density 0.007/height 40 instead of Viridian Forest's 0.009/44, and ordinary
island towns/coasts/mountains received additional coloured mist. The early
owner return also bypassed the ordinary local-light room haze. Native RC17/
RC15 captures reproduce all five categories before the change.

`IndoorMist.profile` now resolves each authenticated source family against the
existing Kanto definitions: 47 caves share the cave profile object, 15 canopy
fragments share the forest profile/tint/datum policy, 142 ordinary exterior or
harbor fragments and 10 mountain fragments receive no extra mist, and 52 room
fragments use the active map's actual light-shell height and the ordinary
room colour/density. A weak map cache keeps room queries allocation-free after
initialization and updates height when the active shell changes. Dark rendering
and absent/disabled/foreign room lighting return no profile. The existing
`KascSeviiScenery.mist` accessor delegates to this single policy.

Ordinary Kanto calls retain their former branch order and room allocation
behavior. Other KASC custom regions keep their existing atmosphere ownership.
No collision, tiles, geometry, flags, saves, map IDs, presets or engine sources
change. This cause changes atmosphere only.

## Repeatable checks

Run `tests/sevii_mist_conventions_test.lua` from the mod repository with the
existing LÖVE Lua test host. It checks all 266 generated family records against
the actual Kanto policy objects, forest colour/datum, room light ownership,
cache identity/live height, dark rendering and malformed-owner rejection.
The complete Sevii suite and the mist prewarm/composite/curved/mobile-path GPU
checks are recorded in `evidence/sevii-mist-conventions-20261008`.

For actual packaged rendering, load the before KASC RC17/VASC RC15 or after
KASC RC17/VASC RC16 pair in an unmodified gen1recomp 0.3.61 checkout. Run the
included `sevii_mist_conventions_native.lua` as a `POKEPORT_DRIVER` with a fresh
QA identity and `SEVII_QA_OUTPUT`, `HABITAT_QA_ROOT`, and `SEVII_KASC_ROOT` pointing
to the QA output and the KASC source repository (for its common driver helper).
Set `SEVII_MIST_FIXED=1` for the after assertions; use `SEVII_MIST_CAMERA=0` for
the separate 2D capture fixture, and omit it for Voxel. The driver checks all
266 source-family API resolutions and captures five Sevii families plus five
Kanto references under DAY/NIGHT and dynamic lighting ON/OFF. It pins clocks,
uses prepared champion/no-encounter state and finds a real walkable non-warp
cell nearest each declared point. This is an atmosphere fixture, not a full
playthrough or resource-balance test. Its complete marker is
`SEVII_NATIVE_MIST_CONVENTION_PROOF_COMPLETE` with 266 API rows and 40 frames.

Room API rows made before presentation have no current light owner; the native
room frames separately prove the lit/unlit policy. The 52 source-room unit
cases test that policy with controlled live lighting state; they do not claim
52 complete rendered room walks. Mobile-path GPU tests run on desktop hardware
and do not establish fixes on the original Adreno 830 device. Full camera,
weather, preset and geometry closure remains outside this cause.

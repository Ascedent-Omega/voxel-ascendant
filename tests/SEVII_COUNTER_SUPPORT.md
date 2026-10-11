# Joyful Game Corner countertop footing

The U-shaped replacement counter declared support height 14 over its entire 128×48 footprint. The original west aisle, rear gap and centre floor are open, so actors there floated 14 pixels above the actual mesh. The footprint still owns the source drawing; support now applies only to the real countertop runs. Open areas return no furniture support and use the existing floor datum. No vertices, collision, source labels, settings defaults or Kanto models are changed.

`sevii_counter_support_test.lua` checks all 6,144 half-pixel points against the actual generated countertop boxes, eight authenticated open-floor cell centres and out-of-bounds coordinates. Five related scenery/floor/room component checks pass. The parent 56-module suite remains separate from these reruns.

Native before RC17/RC14 and after RC17/RC15 proofs cover all eight Voxel footing values (14 → 0), real aisle movement from (1,3) to (1,2), furniture OFF and restoring ON. Matching 2D coordinates and real movement are recorded separately: 2D does not execute the Voxel actor-footing path. QA teleports, a champion/team and disabled encounters are explicit fixtures. The public v1 driver is the exact Voxel fixture, and v2 adds the separately recorded 2D path.

The full native expanded terrain plus uploaded claimed furniture mesh probe covers all 266 maps / 95,745 samples (three interior points per walkable/water cell). No sampled surface is missing in either run. Twenty-four Game Corner support discrepancies disappear; 92 other chair-edge/descending-stair datum differences remain. Both windings are counted, matching the renderer's disabled face culling, but this does not establish all-angle visibility, topmost support, every point in a cell or all settings. The other differences remain REVIEW pending interpretation against actual actor poses and existing Kanto conventions.

Exact 16-image Kanto comparison and continuous seven-chapter journeys belong to the parent RC17/RC14 receipts. They are included as parent references, not relabelled as RC15 runs. Foreign ownership guards and related scenery component tests remain valid; the changed function only constructs the owned Sevii Game Corner counter model.

Evidence and complete package/driver SHA receipts are in `evidence/sevii-counter-support-20261008`. No ROM, NAS log, player save or private token is published. Engine source files remain unchanged; installed mods and player profiles are untouched.

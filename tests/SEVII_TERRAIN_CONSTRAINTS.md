# Sevii terrain constraints

The former flood fill merged adjacent collision-free movement layers 3 and 5. This erased original terrace boundaries and introduced contradictory stair constraints. On a contradictory group, the generator silently flattened the whole group. The corrected fill keeps original movement labels distinct; physical relief comes from authenticated stair mouths and the existing Kanto 6-pixel course, never from the numeric movement label.

Where cascade processing admits water, water label 1 and bank label 3 share a course because the native Surf mount/dismount permits that transition. Layer 5 terraces remain separate. Authored source connections still determine joins. Source ordering is deterministic, and contradictory constraints now raise a descriptive error instead of exporting flat terrain.

The regenerated profiles change courses/related prop rise in 33 runtime fragments. The complete solver has 191 nodes including two waterfall-only nodes; the diagnostic counts 189 walk-region nodes. No conflicting groups remain. Sixteen formerly flattened/merged stair flights acquire their existing six-pixel rise. Source map types, animation data and Kanto profiles retain their existing values.

## Repeatable checks

`sevii_terrain_constraints_test.py` creates independent fixtures: adjacent original movement layers separated by a stair must produce a six-pixel rise; incompatible seam constraints must raise. The full authenticated regeneration and before/after flight diagnostics are recorded under `evidence/sevii-source-elevations-20261008`. The paired KASC importer revision 8 preserves original movement labels and blocks invalid cliff crossings in both views.

Native evidence uses immutable KASC RC14 / VASC RC10 before, KASC RC17 / VASC RC14 after, the same coordinates/camera and matching native color options. Seven real movement cases supplement the exhaustive metadata/collision probe. Separate continuous seven-island and exact Kanto reference runs verify the integration; each receipt records the actual package SHA, driver SHA and engine identity.

## Scope still open

Terrace constraints do not establish complete geometry coverage. Projected terrain triangles and actual uploaded prop meshes expose unresolved Center chair/descending stair support differences. All-angle visibility, water/enclosure materials, settings combinations and original Android Adreno 830 failures still require further investigation. This cause does not claim they are resolved.

No engine source, installed mod, savegame, ROM or NAS log is changed or published. Original movement semantics are documented in the paired KASC `tests/SEVII_SOURCE_ELEVATIONS.md` with primary source links.

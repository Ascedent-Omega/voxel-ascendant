# Repeatable Sevii parity audit

Use matching complete KASC and VASC packages, including the local Sevii bundle and bundled assets, in an isolated engine host. Source worktrees alone omit ignored assets. The audit modifies only its dedicated QA save profile and output directory. It never changes engine sources or a player save.

Generate independent source expectations with `tests/sevii_source_quality_test.py --importer <KASC>/scripts/import_sevii_bprd.py --rom <private BPRD ROM> --output <qa>/source-oracle.json`. The oracle exports semantic coordinates, not ROM artwork. The supplied importer and source manifest must match the bundle.

Launch LÖVE 11.5 on the isolated host with these environment variables:

```sh
POKEPORT_IDENTITY=vasc-sevii-parity-local-qa
POKEPORT_GAME=red
POKEPORT_DRIVER=<VASC>/tests/sevii_native_voxel_driver.lua
HABITAT_QA_ROOT=<existing output directory>
SEVII_KASC_ROOT=<KASC>
SEVII_SOURCE_ORACLE=<qa>/source-oracle.json
SEVII_VISUAL_MODE=full
SEVII_INVENTORY_ONLY=1
```

Require both exit status zero and `SEVII_PARITY_QUALITY_PASS` for a source screenshot review, `SEVII_FULL_VOXEL_AUDIT_PASS` for the complete battle/visual driver, or the complete `SEVII_COUNTS` / `SEVII_UNCLAIMED` receipts for inventory-only mode. `audit.json` contains aggregate counts; `map-audit.json` lists every owned runtime map, source, tileset, cell coverage, water/grass cells, props, buildings, actors, warp/connection counts and battle style. Missing tile mappings fail with map, tile ID and coordinate. `unclaimed.json` must be empty. The real native shape and mesh providers perform the checks; a registered profile alone is insufficient.

Export the measured matrix with:

```sh
python3 tests/sevii_audit_matrix.py --input <qa>/map-audit.json --output <qa>/matrix.csv
```

For all source-area screenshots, replace `SEVII_INVENTORY_ONLY=1` with `SEVII_PARITY_QUALITY=1` and add `SEVII_PARITY_REFERENCE_2D=1`. This captures each source's 2D and voxel view at the same map and cell. `SEVII_PARITY_KIND=room`, `cave`, or `exterior` selects one family; `SEVII_PARITY_SELECTED=<comma-separated source names>` selects specific repros. Leave these filters absent for the complete review. Test both `SEVII_VISUAL_MODE=full` and `basic` when original voxel assets and replacement models are affected. The 2D reference changes no map, collision, quest or actor data. `review-sources.json` records the chosen original-source coordinates.

A shape check does not prove visual parity, performance or mobile GPU behavior. The matrix deliberately keeps visual and mobile fields unverified until separate screenshots and device evidence are reviewed. Keep failed executions alongside successful runs. Do not crop or mask changed Kanto pixels to make a regression comparison pass; freeze clocks and actors in the QA fixture before renderer warmup.

## Adding another Gen3 source map

Add the source to KASC's `scripts/sevii_maps_bprd.json`, import with `scripts/import_sevii_bprd.py`, then run `scripts/audit_sevii_geometry.py` against the generated bundle. Keep existing map and flag IDs. Generated source-cell collision, original warp indices, source origins and atlas dimensions are part of the presentation contract.

Build VASC recipes with `scripts/build_sevii_voxel_profiles.py`. Update reviewed source metatile roles and secondary-atlas tables there; do not patch individual runtime map names to hide missing roles. Reuse Kanto shapes, scenery, materials, room fixtures, stairs, water, lighting and camera conventions. Emit source-relative object footprints so fragments share one identity and geometry phase. Native collision and the exact door opening remain authoritative.

`KascSeviiScenery.profile` must admit the exact owner, source, origin, dimensions, tileset, atlas/block layout and collision data. Run the independent oracle, every-cell/mesh audit and source screenshot pairs after regenerating. Battle backgrounds use the admitted map family; authored ARENA artwork belongs only to ARENA. MAP, DISCS and Terrarium retain their own geometry. Presentation identities use the owning species registry's canonical source dex, while private save-compatible dex slots remain unchanged.

Finally walk the new map's entrances and exits, events and trainers in 2D and voxel, save/load there, return by ferry, and compare the fixed Kanto reference list. A successful static report does not replace this playthrough.

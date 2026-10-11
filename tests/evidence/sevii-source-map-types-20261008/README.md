# Source map type correction: native evidence

All 266 native maps are audited against 135 authenticated original map headers. Old RC14/RC9 packages report 143 family mismatches; RC14/RC10 report zero. The portable stages reuse existing Kanto families. Source metadata is semantic only: no ROM, banks, raw NAS logs or player saves are included.

## Same-coordinate native frames

| Source | Runtime coordinate | Before Terrarium | After packaged Terrarium | After packaged 2D |
| --- | --- | --- | --- | --- |
| One Island | KA_SEVII_ONE 13,14 | [room floor](fix-before-quick-source-style-before-terrarium0361-v5/town-terarrium.png) | [city floor](fix-after-quick-source-style-packaged-terrarium0361-v6/town-terarrium.png) | [native](fix-after-quick-source-style-packaged-flat0361-v6/town-flatB.png) |
| Kindle Road | KA_SEVII_KINDLE_NORTH 12,19 | [room furniture](fix-before-quick-source-style-before-terrarium0361-v5/route-terarrium.png) | [grass](fix-after-quick-source-style-packaged-terrarium0361-v6/route-terarrium.png) | [native](fix-after-quick-source-style-packaged-flat0361-v6/route-flatB.png) |
| Mt. Ember | KA_SEVII_MT_EMBER_EXTERIOR_X0_Y20 14,4 | [room](fix-before-quick-source-style-before-terrarium0361-v5/mountain-terarrium.png) | [existing mountain family](fix-after-quick-source-style-packaged-terrarium0361-v6/mountain-terarrium.png) | [native](fix-after-quick-source-style-packaged-flat0361-v6/mountain-flatB.png) |

Corresponding before/after DISCS and 2D files and after world views are in each execution folder. `source-style.json` records actual map/cell, source, requested/actual stage, style and rendered frame count. Pokémon stats and animated poses are randomized native fixtures; these screenshots are not exact pixel comparisons. No ARENA painting is introduced for these locations. Its existing explicit recovery remains visible in retained diagnostic attempts.

## Receipts and limits

- [Original independent header metadata](original-map-header-types.json), [profile byte preservation](source-map-type-export-proof.json), [current summary](source-map-type-fix-current.json).
- [55 component tests](component-tests.json), [native completion markers](native-markers.json), [1,917 unchanged engine sources](engine-source-verification-source-style.json).
- [16 exact Kanto comparisons](kanto-pixel-regression-source-style.json). Viridian/Cinnabar use matching isolated camera histories; the [mismatching long history](kanto-pixel-regression-source-style-full-history.json) is retained. The selected full frames match without crops, masks or tolerance.
- [Superseded introduction/artwork fixture assertions](superseded-fixtures.json) retain the actual errors.

The runs use isolated QA identities, teleports and prepared champion teams. This cause-specific evidence does not complete rendered height/seam checks for all maps, full settings conventions, Android GPU follow-up, continuous journey balance or the original Groudon provider/animation report. Those scopes remain separately open. Repeat instructions: [SEVII_SOURCE_MAP_TYPES.md](../../SEVII_SOURCE_MAP_TYPES.md).

# Source tile animation follow-up

The RC13/RC8 completion audit found a local importer omission. It is additional
work, not an Android-only blocker and not a claim of animation parity.

The native diagnostic loads all 266 imported runtime maps on engine 0.3.61.
Their source atlases use nearest filtering. None declares `animatedTiles` or
an inherited tile animation; both 2D and Voxel atlas images remain static.
105 runtime maps contain water. Real `Water.begin` rendering advances through
six representative water families in Voxel, including Berry Forest, Icefall
and Ember Spa. That proves the existing shared water pass runs on desktop,
not that source tile animation is imported or works on Android.

`sevii_source_animation_inventory.py` independently decodes the user's exact
German BPRD ROM. It verifies frame-bank hashes, pointer tables and code
references before composing original metatiles at phases 0 and 1. Source
pixels change on 26 water, 7 shore, 11 flower and 10 steam source maps; these
sets overlap. The machine receipt distinguishes whole source maps from
individual runtime fragments and excludes fully occluded phase changes.
Other secondary callbacks remain separately unclassified. The reference is
[pret's original animation code](https://github.com/pret/pokefirered/blob/master/src/tileset_anims.c).
No ROM pixels, bank bytes or ROM file are exported by the diagnostic.

Repeat the source check with:

```sh
python3 tests/sevii_source_animation_inventory.py \
  --importer <KASC>/scripts/import_sevii_bprd.py \
  --rom <private German BPRD ROM> \
  --output <qa>/source-map-animation-inventory.json
```

Run `tests/sevii_native_map_animation_driver.lua` in the same isolated complete
package host as the documented parity driver, with `SEVII_QA_OUTPUT` and
`SEVII_KASC_ROOT` set, and once with Voxel OFF and once ON. The component
wrapper used in the retained receipts sets `SEVII_COMPONENT_CAMERA=0` or `1`
before the new game. Require exit zero, `completed=true` in `map-animation.json`
and `SEVII_MAP_ANIMATION_DIAGNOSTIC_PASS`. Progression, team, teleports and
Water FULL are fixtures. The driver observes real engine clocks and native
water passes; screenshots alone are not an assertion of animated pixels.

The next correction must preserve the existing atlas, collision, map, flag
and save IDs; export authenticated source phases through the private importer;
and reuse Kanto Voxel conventions with bounded preparation and no per-frame
resource churn. Compare every affected source phase, actual native rendering,
save/load and unchanged Kanto. Neither the diagnostic nor the current ZIPs
implement this correction. Keep Animation open in the completion matrix.

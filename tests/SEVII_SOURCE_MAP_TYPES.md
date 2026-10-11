# Original Sevii map types and battle families

Imported atlas IDs differ from native `OVERWORLD`, and island/route IDs do not contain the Kanto city-name patterns. The previous family resolver consequently classified 143 exterior runtime maps as interiors. That made the Terrarium on Kindle Road draw room furniture and an indoor floor.

Each of the 266 admitted source profiles now retains `sourceMapType` from the authenticated BPRD original header. The existing Kanto city, grass and interior families handle original towns, routes and rooms. Reviewed mountain, canopy, coast and cave roles retain their matching Kanto families. No new painting, material, collision, gameplay map, weather rule or Kanto branch is introduced. Missing metadata on an admitted unclassified Sevii map fails with its map/source identity.

The source structure and numeric enum come from the primary definitions [MapHeader](https://github.com/pret/pokefirered/blob/master/include/global.fieldmap.h) and [map types](https://github.com/pret/pokefirered/blob/master/include/constants/map_types.h). The verified German revision uses `mapType` at header offset `0x17`. The independent oracle follows original group/header pointers directly; it does not call the presentation generator's map decoder or style resolver.

```sh
python3 tests/sevii_source_map_type_oracle.py \
  --importer <KASC>/scripts/import_sevii_bprd.py \
  --rom <private authenticated BPRD ROM> \
  --output <qa>/original-map-header-types.json
```

Run `tests/sevii_source_battle_type_test.lua` from this mod's directory with the matching engine modules on the Lua module path. It checks all 266 profile identities against the separately exported 135 original headers, all resulting Kanto families, missing metadata rejection, foreign ownership and unchanged Kanto classification. The full Sevii component suite passes 55 tests.

For native verification, load complete matching packages in an isolated engine host and set:

```sh
POKEPORT_IDENTITY=vasc-sevii-source-style-local-qa
POKEPORT_GAME=red
POKEPORT_DRIVER=<VASC>/tests/sevii_native_source_style_driver.lua
SEVII_QA_OUTPUT=<existing output directory>
SEVII_KASC_ROOT=<KASC>
SEVII_STYLE_ORACLE=<qa>/original-map-header-types.json
SEVII_STYLE_FIXED=1
SEVII_STYLE_SCREENSHOTS=1
SEVII_COMPONENT_BATTLE_MODE=terarrium
```

Use `flatB` for DISCS, or `SEVII_STYLE_CAMERA=0` for native 2D reference frames. Require exit zero, no driver error, a completed `source-style.json`, 266 checked maps, zero mismatches and `SEVII_NATIVE_SOURCE_STYLE_PROOF_PASS`. Older packages omit `SEVII_STYLE_FIXED`; their completed diagnostic must still report the 143 mismatches, rather than being presented as a parity pass.

The [evidence](evidence/sevii-source-map-types-20261008/) contains untouched same-coordinate frames before/after at One Island, Kindle Road and Mt. Ember, actual RC14/RC10 packaged runs, native markers, component results, original header metadata and exact Kanto image comparisons. The 266 resulting families are 116 grass, 60 interior, 47 cave, 17 city, 15 forest, 10 moon approach and one coast. Removing only the newly added field restores the preceding recipe file byte for byte.

ARENA artwork remains an exact reviewed binding owned separately from the family resolver. These three example locations have no reviewed painting, so selecting ARENA explicitly recovers to DISCS with a diagnostic receipt. The discarded QA attempts incorrectly required an ARENA painting or omitted native introduction input; their errors are retained. The successful native screenshots verify DISCS and Terrarium, and do not claim newly authored ARENA art. Pokémon stats/animation frames use the native randomized QA team and are not pixel parity fixtures.

Kanto comparisons use the complete RGBA frame with no crop, mask or tolerance, fixed clocks/actors, native GBC options and renderer warmup. Viridian and Cinnabar use matching isolated map histories because a long fixture sequence changes their camera solve; the mismatching full-history comparison is retained. This proves the selected reference captures, not all possible camera histories.

The native tests use QA teleports, champion/team fixtures and disabled random encounters. They do not prove journey balance, every camera angle, complete geometry/settings review, Android GPU behavior or the original Groudon provider/animation state. Those areas remain separately open in the audit matrix. Engine source hashes remain unchanged.

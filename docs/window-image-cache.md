# Window far-view cache

`SilphWindows.geometry` is the single source for both the fallback scene and the offline capture. It expands the native building footprint to the interior dimensions and applies the room's floor height before splitting geometry. Revision 2 extends the captured horizon to 6144 world pixels, including the connected Cinnabar coast; distant terrain uses coarser sampling. The moving elevator retains its previous 3200-pixel live range. The nearest 480 world pixels around the room center stay in 3D; distant geometry is captured into six skyless cube directions at 768 pixels per face. Empty sky and empty light layers are omitted. Images are cropped; land, nighttime window lights and surface/foliage masks retain the rooftop renderer's clock and seasonal treatment.

The shipped index is `data/window_cache.lua`; assets live in `assets/scenery/windows`. Every room and Lavender Tower style has an independent key. A fingerprint of exterior source maps and tilesets, capture revision, interior dimensions and scenery configuration must match before images load. Interior door/event changes do not invalidate exterior captures. Missing or failed assets select the previous live geometry path. The lift always uses live geometry because its elevation changes continuously. No additional user setting is needed: the existing real-windows setting controls the whole feature.

`RooftopCache.loadMeta` owns decoded textures and meshes until successful return. HorizonWall takes ownership afterwards and the shared configurable map-cache allowance releases them on eviction; estimates include unique mesh allocations and owned window images. There is no per-frame image capture, persistent runtime screenshot store, or added exterior NPC simulation. Far geometry has the same approximate motion parallax as the rooftop capture; nearby streets and facades retain true parallax.

Rebuild in an isolated native QA host containing the worktree mod:

```
POKEPORT_IDENTITY=vasc-video-polish-qa POKEPORT_GAME=red \
POKEPORT_DRIVER=<worktree>/tests/native/bake_window_cache.lua \
WINDOW_BAKE_DIR=<existing-absolute-output-directory> <love> <qa-host>
```

The driver discovers supported rooms from native map definitions and the actual exterior facade, then writes all images, `near.bin`, and `index.lua`. Copy room directories into `assets/scenery/windows` and the index into `data/window_cache.lua`. `WINDOW_FILTER` restricts discovery to matching map IDs when adding room families. A separate source-map family can be baked with `WINDOW_SOURCE` pointing at its generated-data root and `WINDOW_SUFFIX=-rb`; merge its index explicitly. `WINDOW_RESUME=1` reuses complete captures only when revision, dimensions, scenery configuration and source fingerprint match; it never accepts old-revision images. Geometry generation yields on a 30ms work budget rather than waiting one frame for every row. Do not relabel fingerprints without regenerating the matching source geometry.

Validation: `window_image_cache_test.lua` checks fallback and floor/configuration guards; `window_cache_decode_test.lua` checks crop projection and partial-allocation cleanup; `window_cache_assets_test.lua` checks shipped binaries, dimensions and masks. `tests/native/rc14_window_cache_performance.lua` compares live/cached/cached/live at identical positions, renders three camera modes and day/night, then tests repeated room eviction. The packaged candidate must also pass the native loading/seating/window driver.

## Facade expansion, 2026-10-01

Configuration suffix `:facades-20261001` invalidates photographs made before the expanded native facade and floor bindings. Connected forest and plateau source maps are included; Safari huts retain their own connected Safari region. Native S.S. Anne cabins use six separately guarded room boundaries. Ship views retain hybrid nearby geometry rather than flattening it into house bitmaps. The full rebuild covers all three source families and both exterior styles.

Guardhouses deliberately remain outside HouseWindows: their original flat windows supply InteriorLights portals, while GateMaps replaces only map artwork. All seven Lavender Tower interior floors remain excluded.

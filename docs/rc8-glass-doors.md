# rc.8 glass sliding-door prototype

The request is to make the interior exit match the glass entrance implied by modern exterior buildings, with a later-generation-style sliding cue. The follow-up explicitly asks for a fixed destination image behind each side of the door, so opening does not require a moving portal perspective.

## Scope and appearance

Eleven native Pokémon Centers, eight native Marts, Celadon Mart 1F and Silph Co. 1F use the new treatment. The interior classifier validates the existing native profile (tileset, dimensions, generation and connections) and an exterior or LAST_MAP destination. Upper-floor stairs, teleport pads, elevators, card-key doors and residential doors do not opt in. Exterior models opt in only for known modern entrance destinations.

Two framed tinted leaves separate over approximately 0.32 seconds, with a 34/44-pixel approach/leave hysteresis. Interior leaves disappear into the wall; exterior leaves slide to either side. Native warps, fades, arrival movement, collisions and story blockers remain authoritative. A closed stationary version remains present in rooftop city panorama geometry, including its cache fingerprint.

Behind each opening is a fixed native destination view. The 43 640×480 PNGs were captured from actual reciprocal Red warps in an isolated LOVE host with KASC 6.7.29, without actors or HUD. The two Celadon Mart exits have separate street views. `assets/doors/SOURCES.json` records map, cell, dimensions and hashes; `tools/qa_glass_door_views.lua` recreates them using POKEPORT_DRIVER and VASC_DOOR_ASSETS. Interior pictures are cropped to the narrow exterior aperture rather than stretched. Street views receive the outdoor clock tint. These are static images: destination weather, NPC movement and customised map art are not live previews.

The cue is original procedural audio, generated reproducibly by `tools/generate_glass_door.py`; no game recording is sampled. One reusable Source follows SFX volume. No source is created each frame. A narrow, idempotent native warp bridge replaces only Go_Inside/Go_Outside at eligible voxel entrances, restores the binding on errors and preserves return arity. Already opened doors do not replay the cue at the fade. Audio failure keeps the native cue.

## Runtime cost and ownership

Moving leaves reuse retained geometry; only their transforms change. Door-bearing prop lists are cached. Destination images and backdrop meshes load during preparation, have explicit Assets cleanup and do not render another map. No terrain, quality, draw-distance or menu settings are reduced. The feature adds small door meshes and destination textures; no zero-cost or universal FPS claim is made.

## Verification

- `glass_doors_test`: guards, native callback/return/error/reload behaviour, mute and audio fallback, symmetric reversible motion, no idle/repeated warp sounds, exterior bearings, resource preparation, destination texture identity, crop, tint restoration and unload cleanup.
- `interior_boundary_test`, `interior_unique_planes_test`: exit niches, elevator openings, teleporter exclusions and wall coverage remain intact.
- `furniture_receipt_test`, `furniture_light_descriptors_test`: static ownership and live light descriptors remain intact. The light test's existing seasonal dependency mock was completed for the current renderer.
- `rooftop_geometry_cache_test`, `rooftop_sampler_lifecycle_test`: rooftop cache and draw-state isolation remain intact.
- Native LOVE/macOS acceptance in `artifacts/glass-doors-20260930`: Center, Mart, Celadon and Silph interiors; Center and Silph exteriors; actual native entrance/exit controllers; paired motion and audio decoding. Asset capture validates all 21 reciprocal entrance mappings.

The prior rc.7 panorama caveat remains: Route 13 toward Silph is reproduced and fixed; the exact submitted Lavender viewpoint has not been matched.

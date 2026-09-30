# Voxel Ascendant 3.0.57 — world performance, doors and volcano

- Reduces repeated overworld preparation, terrain/shadow work, lookups and allocations; retains default visual quality, live actors/weather, menus and controls. Includes battle-world and arena-result reuse. No universal FPS improvement is claimed.
- Modern public buildings use matching sliding glass doors inside and outside: Gyms/Dojo, Pokémon Centers, Marts, Bike Shop, department store, Silph Co. and route/forest gates. Includes an original sliding sound and retained destination pictures. Exterior glass follows window lighting at night; frames remain shaded.
- Ordinary houses and other supported entrances use matching single wooden doors in consistent colours, with corrected proportions across adjacent exit tiles.
- Includes seated-character/style corrections, Your Look fixes, Viridian Center terrain elevation, Pokémon Tower grave fields, rooftop FLY under native requirements, open-lookout rain and upstairs loading indicators.
- Repairs the Route 13 panorama gap toward Silph Co., the related Lavender east-edge exclusion and retained neighbour terrain after cache eviction. The exact reported Lavender screenshot angle was not reproduced; see QA notes.
- With KASC 6.7.30, renders Pyro/Blaine's compact volcanic battle platform, approach and monumental overworld-matching volcano. Without KASC, the original story Gym remains.

Update alongside **KASC 6.7.30**. Replace the existing mod; no new save or option reset is required. Optional resolution reductions remain opt-in. Desktop native tests and package checks passed; physical Android/Windows/Switch performance has not been measured.

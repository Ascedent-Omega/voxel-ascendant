# Guardhouse Smart Maps

GateMaps decorates only native Gen 1 gate panoramas. Painted windows remain flat and provide InteriorLights daylight/night portals. Both wall maps use the existing illustrated Smart Map artwork: the Kanto widescreen chart and the seven-island Sevii master. Source and adapted-renderer hashes are recorded in assets/maps/gate-atlas-sources.json.

The nearby prompt is English by default and German through SetupLocale. A opens the shared illustrated 576x324 Smart Map over the frozen world. Directions select a place, A zooms, SELECT opens its information, START switches region and B returns. The read-only factory derives from the existing Kanto/Sevii companion; it registers no screens or menu hooks, and receives no Fly callback. Public KASC without the Sevii expedition still displays all seven island locations, with no player marker invented from a Kanto position.

Dismissal lasts until the player leaves the nearby area. Map/save changes invalidate the frame. Native interactions run first, and no inventory, flags, travel destinations or unlocks are modified. Classic rendering retains its original artwork and interactions.

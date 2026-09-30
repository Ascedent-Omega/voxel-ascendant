# Cobble cyclists and seats — 3.0.61-rc.2

Based on 3.0.61-rc.1 (public base 3.0.60), preserving the loading language fix.

Reproduced Route 17 map.entered failure: `no Cobble wardrobe for cue-ball`. Bicycle actions previously invoked the hero-only wardrobe baker for NPCs and stopped subsequent NPC binding. Both existing supplied NPC rigs now have baked idle/walk/blink bicycle clips, using the existing field equipment and articulation. No gameplay, trainer, encounter or wardrobe selection changes; standing/swimming Cue Balls keep their normal artwork.

The optional older Cobble Characters source predates ascendantSeatSource. The host now carries its known NPC source identity into such definitions and falls back to its bundled action provider if an optional provider throws. Current embedded Cobble mother, casino occupants and player already sit; no speculative changes to their furniture/geometry.

Validation: cobble_rider_actions_test.lua (prepared actions, no runtime baker, normal walk preserved, old-provider action failure, old-provider identity admitted by real seat resolver); cobble_seat_profiles_test.lua (45/45 registered Gen1 NPCs); hoenn_visitor_seat_test.lua. Native isolated game: seated player/mother; casino NPCs; every rider on Routes 16/17 bound with the correct Cobble bicycle identity, Route 18 Bird Keepers retained. Logs/screenshots under artifacts/cobble-riders-seats-20260930 in the parent workspace. Bicycle atlases visually inspected. User's exact affected seating location/additional Card installation is not yet confirmed.

Reproduce atlases with tools/bake_cobble_riders.py and the LÖVE executable (Pillow required). The script reads bundled model geometry/palette and renders via the existing cuboid baker; no runtime generation cost for these NPCs.

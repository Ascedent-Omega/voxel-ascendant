# VASC 3.0.61 verification

Base: public VASC 3.0.60, verified against the GitHub release asset SHA-256. Only the three Halloween attachment runtime files change; every other baseline runtime file and asset is byte-identical. The new release does not promote unrelated release-candidate changes.

Three targeted tests pass: accessory contact/face clearance across small and wide cards, height, yaw, lean, mirror and breathing; calendar boundaries and exclusions; human atlas loading lifecycle. The exact packaged runtime passed a native macOS/Love 11.5 game run with Voxel and Cobble NPCs, front/back/orbit views and calendar OFF. Private fixtures force hats for visibility; production selection is preserved. The approved correction is the second hat patch with the brim seated inside the crown.

All packaged Lua files compile with the target Lua runtime. Archive CRC, source/package equality and both file-hash receipts are verified by prepare.py. Desktop verification is complete; physical mobile devices were not tested.

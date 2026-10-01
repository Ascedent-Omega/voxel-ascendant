# Center sitter artwork

The Cobble figure uses the existing Kanto roster renderer and original-v3 Bedrock rig from ascendant-cobble-characters/tools/roster_source.py. The local preview loads the owned seated model, with the same face/hair rig, palette-index cube geometry and eye/lid animation used by other roster characters. It is an authoring/export preview, not an upstream Cobblemon conversion service.

Model, animation, poser and palette sources are retained under assets/characters/center-seated/cobble/model. The transparent 256×320 exports form a 4-column blink × 4-direction sheet. The fixed couch uses the right-facing row; all views remain available for review. The preview's export button POSTs 16 named PNGs to a local /export endpoint. QA used a temporary localhost-only exporter; no remote upload was performed.

Voxel artwork was generated from the existing seated HD source and the packaged Voxel nurse as a style reference. HD keeps the existing source when its optional pack is available. Per-style sources, bounds and hashes are in assets/characters/center-seated/provenance.json.

This tile-authored figure stays attached to its original cushion. No extra NPC, collision or furniture is introduced. Walking sprites OFF keeps the original figure.

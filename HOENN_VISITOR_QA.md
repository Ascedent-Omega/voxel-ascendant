# Hoenn visitor — local visual candidate

Base: VASC 3.0.53-rc.18 (`84444645`). Candidate: `3.0.53-rc.18.hoenn.1`. Pair with KASC `6.7.29-rc.2` from this task. Neither candidate was published or installed into a player's game.

The native identity `SPRITE_KA_HOENN_VISITOR` resolves only in Gen 1 to its own HD, voxel or Cobble Human atlas. Every enhanced style includes a native fallback with six 16x16 frames. Full atlases have 3 columns (stand / step / other step) and 4 rows (down / left / up / right). Other female NPCs retain their own identities.

Select **Your Look → Character style → Original 2D / HD / Voxel HD / Cobble Human**. Cobble Human is also listed under PEOPLE STYLE. This candidate bundles Cobble artwork for the Hoenn visitor; other characters without matching artwork keep HD. The setup preview correctly shows the visitor for this new choice. Existing defaults are unchanged. Missing optional artwork falls back to HD; disabling HD people restores KASC's native Gen-1 renderer.

Rendering changes do not alter save progress, NPC placement, dialogue or encounter rules. Runtime spawn events bind a returning visitor immediately; loading an existing campaign does not require starting again.

## Validation

- `tests/hoenn_visitor_visuals_test.lua`: 81 assertions passed. Repeated HD/Voxel/Cobble/native switching, atlas and native-file selection, dimensions, adult scale, native restoration, unchanged position/facing/resident/save data, runtime spawn, generation restriction and missing-art fallback.
- `tools/hoenn_visitor/render_check`: 68 GPU pose draws passed with LÖVE 11.5. Actual engine `SpriteRenderer` for 32 native direction/walk combinations, plus 36 full-atlas frames. A test-only absolute-file loader allows reading the two isolated worktrees. The four-style comparison was visually inspected.
- Cobble rig baker: all four directions, 12 walking phases + 4 blink phases + idle passed. Geometry, animations, poser, palette and rendered clips are included under `assets/hoenn_visitor`.
- Existing KASC-player-rebinding test passed.
- Existing Setup Card rules: 77 checks passed. Context visibility and invalid-resume-state tests passed.
- All Lua source files compile; `git diff --check` passes.

These are renderer, binding and fixture tests, not a complete graphical campaign playthrough. The standard VASC 3-pose atlas drives current in-game presentation; the editable Cobble model and its full motion clips are additional supplied sources.

## Rebuild

From the VASC root, run `python3 tools/hoenn_visitor/build_model.py`, then run the `tools/hoenn_visitor/baker` LÖVE project with `HOENN_VASC_ROOT` set to this root. Finally run `python3 tools/hoenn_visitor/pack_atlases.py`. Pillow is needed for packing. See `assets/hoenn_visitor/PROVENANCE.md` for generation prompts and original local rig sources.

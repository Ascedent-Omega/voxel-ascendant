# VASC 3.0.54 — Keep the selected battle view

Standalone hotfix based on public VASC 3.0.53. Local RC development is excluded. Includes the per-device mobile shadow fixes from 3.0.53.

## Changes
- Keep the selected Gen 1 battle environment when a trainer or Pokemon overlaps the attack/message HUD, exceeds the preferred frame, or cannot satisfy the ideal composition. These checks previously could freeze the picture, relocate the battle and switch MAP to Terrarium after a timeout.
- First try the existing camera corrections. If the composition remains imperfect, retain a physical camera pose and render fresh actors, animations and HUD in the same environment. The player can change the view manually using the existing battle controls.
- Avoid repeating the complete camera search every frame. Reconsider the composition on phase changes, Pokemon deployment, orientation changes and manual camera input. Camera transaction rollback and owner changes discard the corresponding temporary state.
- Record a composition-limited diagnostic separately from a renderer failure. This shared Gen 1 path applies to Android, iPhone and desktop.

## Scope and validation
This removes automatic view changes caused by the listed composition checks. An overlap may remain visible until the camera, HUD or view is adjusted. Missing assets, invalid ownership, physically unsupported placement and actual renderer/GPU failures retain their existing recovery handling. Gen 2 camera logic is unchanged.

Native Android/OpenGL and iOS/Metal policy tests on macOS cover a persistent injected trainer/attack-menu collision, fresh MAP frames beyond the old timeout, rotation, menu input and manual ARENA selection. A 3.0.53 comparison reproduces the automatic Terrarium switch. These are not physical phone tests. See QA-REPORT.md for the complete validation.

## Install / rollback
Close the game, update through the launcher or import Voxel-Ascendant-3.0.54.zip, then restart. No save migration. Rollback: complete public VASC 3.0.53 package.

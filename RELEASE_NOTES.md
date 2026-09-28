# VASC 3.0.53 — Mobile shadow hotfix

Standalone hotfix based on public VASC 3.0.52. Does not include the local 3.0.53-rc.* development changes. Recommended KASC pairing remains 6.7.27.

## Changes
- Restore Gen 1 and Gen 2 world/object/character shadow maps on capable iPhone and Android renderers. Existing SHADOWS / OBJECT SHADOWS switches still work; previously saved OFF preferences are preserved.
- Test packed depth, actual depth rejection, render-target support and texture orientation on the current GPU at first use. Correct the Metal/OpenGL texture-orientation difference from the measured result, independently of the phone model or screen orientation.
- Use a bounded 512-pixel mobile shadow map (256 when required by the reported texture limit), with an explicit depth attachment and high-precision depth packing. Desktop resolution and filtering are retained.
- Add shadow sampling to the compact Gen 1 phone shader. Cloud/bird shadows are included where the existing sky/weather policy supplies them; a shader rejection first removes aerial effects, then falls back to the original compact renderer.
- Fix a Gen 2 GLES shader-link mismatch by using matching camera-uniform precision in both shader stages.
- Restore the complete caller graphics state, including nested colour/depth attachments, clipping and transforms. Failed mobile shadow passes are contained and latched for the session instead of repeatedly breaking the world renderer.

## Validation and limits
Native macOS tests exercise iOS/Android policy paths on Metal and OpenGL, actual shadowed pixels, nested render targets, rotation and ON/OFF transitions. Strict GLSL/GLES compilation/linking and targeted regressions are included in QA-REPORT.md. These are not physical iPhone/Android device certifications. GPU admission runs separately on each device; it is a correctness check, not a frame-rate guarantee. A native driver hang or process termination cannot be recovered by Lua exception handling.

## Install / rollback
Close the game, update through the launcher or import Voxel-Ascendant-3.0.53.zip, then restart. Use SHADOWS / OBJECT SHADOWS ON to enable the effect; Gen 2 shadow quality must also be above OFF. No save-format change. To roll back, import the complete public 3.0.52 package.

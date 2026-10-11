# Voxel Ascendant 3.0.63: Omega intro verification

Baseline: public Ascedent-Omega/voxel-ascendant v3.0.62. Scope: shared intro, release metadata and update repository identity.

PASS: real scene rendering and decoding of all four audio sources under LOVE 11.5 (VASC) and LOVE 12 (KASC).
PASS: opening pose anchors, final chord at 4.327 seconds, terminal logo hold without clearing/restart, audible-cursor timing and no backwards pose movement.
PASS: cue timing, exactly one playback during long holds, SFX volume and mute, all-cue skip fade, slow-frame resynchronization, portrait drawing, repeated resource release.
PASS: both shared owners, Gen1/Gen2 entry lifecycle, first-frame save adoption exactly once, mandatory native preparation after long loading, draw restoration, EN/DE/default labels.

Build checks: source Lua syntax, complete archive CRC, archive/source equality and regenerated package file receipts. The base gameplay is retained; a full campaign replay and physical mobile/NX testing were not performed for this intro-only change.

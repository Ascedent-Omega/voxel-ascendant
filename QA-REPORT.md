# VASC 3.0.59 public release verification

Promoted from the tested 3.0.59-rc.1 archive. Runtime Lua and assets are byte-identical; only release metadata, documentation and receipts change. The candidate report below describes the tests performed before promotion; statements that it was not yet published refer to that historical test stage.

# VASC 3.0.59-rc.1 verification

## Reproduction

Native LOVE 11.5 on the existing 0.1.90 host with KASC 6.7.31 runtime, disposable save/identity. Saved KASC Classic style, explicit VASC Crystal battle choice, Gorochu versus Starmie, Gen-3 battle rules and the real backendSplitSpecial67.prepare call. The published code returns no Crystal image even though KASC's direct Crystal provider returns its normal coloured frame. The new focused regression test fails on that published code.

## Fix validation

The corrected native path returns the selected frame with 1,647 visibly coloured pixels. Real native Transform still detaches the move list and keeps ownership of its transformed sprite. Focused tests cover Crystal/HD front and back, normal/shiny, detached stats, HD preloading, explicit Transform flags, native copied moves, Mega and ghost exclusions. Saved stats remain unchanged.

This reproduces a current software defect, not Dias' exact device session: his installed versions and active rules were not supplied. Optional HD artwork is exercised with a provider fixture. No physical mobile-device check or broad performance benchmark. The initial fixed-run image export failed due to a QA-only absolute-path encode call; corrected export rerun passed.

Evidence: artifacts/gorochu-crystal-stats-20260930 in the maintainer workspace (before.log, after2.log, native.lua, gorochu-fixed.png). Public VASC 3.0.58 is retained in full, including the gatehouse/door/visitor fixes. Packaging validates all Lua files, baseline preservation, exact source bytes, CRC and file hashes.

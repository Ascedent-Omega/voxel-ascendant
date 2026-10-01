# VASC 3.0.61-rc.6 — hotel counter verification, 2026-10-01

Base: complete rc.5, isolated checkout without concurrent Halloween changes. The apparent elevated GRANNY is CELADON_HOTEL's native floor receptionist (cell 3,1; pixels 48,16; ground 0). Orbit-card camera-ray bias previously pulled the sprite depth through the reception desk. Gen1CounterOcclusion checks the exact native hotel dimensions, actor state and raw counter pattern 8,8 / 24,25 before overriding only her draw bias to zero. No global bias, position, support height, collision or dialogue changes. Other maps and changed/native-incompatible layouts fall through.

Four focused tests pass in rc6-regressions.json: actual imported hotel geometry, sitter style/cache/OFF contracts, final iOS observation HUD and furniture receipts. native-hotel-desk-isolated2.log passes Voxel/Cobble at pipeline levels 1,2,4,5 (396 clerk draws checked), native floor/position and across-counter interaction. FULL Voxel screenshot visually confirms legs behind the counter. native-center-hotel-locations.log enumerates twelve actual figure placements: eleven Centers and CELADON_HOTEL, and renders the hotel in Voxel/Cobble/OFF. This is not a full visual run in every Center; three Centers per style were already checked in rc.5.

Complete package syntax, model hashes, archive CRC, source equality and receipts are verified by tools/build_local_candidate.py. Unpacked native package acceptance is recorded externally in deliverables/VASC-3.0.61-rc.6-Hotel-Counter-Local/PACKED-QA.md. Physical iPhone/iPad and optional HD-pack scene acceptance remain open. Earlier rc.5 checks and limitations below remain valid.

---

# VASC 3.0.61-rc.5 — completion verification, 2026-10-01

Base: complete local rc.4. Adds the Voxel-HD Center sitter and Cobble sprite exports from the existing local roster/Bedrock workflow. Model, palette, animation, poser and provenance retained; generated Voxel image references the original seated HD character and packaged Voxel nurse. The rejected hand-built block body is absent. Separate cached per-style textures, fixed seat anchor, four baked eye/lid blink frames, failure latch and walking OFF fallback. Three native Centers per style pass, with screenshots reviewed. Optional HD DLC is absent on the QA host: HD selection falls back to Voxel; the retained HD path is covered by the focused stub test, not a native optional-pack run.

Silph Voxel glass lift: quiet continuous 60/120/180Hz motor, faded over travel, observes native SFX volume and pause/exit. The native 1→7 test confirms an active motor source, zero forwarded Collision calls, one arrival PA and stopped source after exit. Other lifts, classic pipeline, glass OFF and decoder failure keep native sounds. Unit covers source reuse, SFX=0, fade, pause, cleanup and fallback. Historical video sound identity and subjective listening acceptance remain unconfirmed; QA system audio is muted.

Eight focused tests in rc5-regressions.json pass. Native completion logs: native-center-accepted.log and native-window-lift-final.log. Full outfit acceptance adds 90 Voxel/Cobble/2D renders to the previous 30 HD renders; 120 current recipes differ from original and are unique per character/style. Source-derived bedroom south-window camera proves current exterior street/neighbor roof/cloud view, not an exact recreation of the historical camera.

Complete ZIP/source/CRC/syntax/model/receipt verification and isolated unpacked package start are recorded under deliverables/VASC-3.0.61-rc.5-Local. Physical iPhone/iPad QA remains open; no connected device was available. Existing rc.4 iOS/Android policy HUD/wish checks remain valid. No installed mods, normal saves or public release changed.

---

# VASC 3.0.61-rc.4 — follow-up verification, 2026-10-01

Base: complete local rc.3. Fixes the iOS vertical reflection of final Mew and binocular HUDs: these passes receive the final composite and must not apply the world-canvas transform again. No changes to world orientation or gameplay.

Five focused regression checks pass (rc4-regressions.log), including actual Mew prompt/choice and active binocular rendering plus complete graphics-state restoration. Native iOS policy run passes landscape/portrait, cancel, reward, save/load; screenshots checked upright. Android policy run from unchanged gameplay passes the same interaction checks. These are macOS LOVE runs with platform policy overridden, not physical iOS/GLES/Android devices.

Further review: all 30 registered RED/BLUE/GREEN HD outfit recipes produce unique raw pixels per character and differ from original; Champion selection succeeds. Cobble/Voxel/2D outfit rendering still requires separate acceptance. The intro NPC is the tile-authored Center sitter; HD replacement exists, Voxel/Cobble remains native. Confirmed artwork gap, no new substitute mesh introduced.

Native visible Nidoking grow sampled for 64 frames, with valid animation and early/middle/late captures. Real Silph ride invokes Collision 100 times and arrival PA once. Fountain attenuation, SFX zero and room exit pass. Lift sound is a plausible source of the historical complaint, not verified by listening. Bedroom window captures remain partly obstructed by TV; no claim of matching the exact old angle.

Physical iPhone/iPad acceptance is still open: no attached device found. Local experimental candidate only; no installed mods, normal saves or public release changed. Build verification is deliverables/VASC-3.0.61-rc.4-Local/verification.json.

---

# VASC 3.0.61-rc.3 — local verification, 2026-09-30

Base: 3.0.61-rc.2 / bd08c92f, retaining its language, cyclist and seat fixes. Isolated LOVE 11.5 QA host with generated Red data and KASC 6.7.33-rc.1. Every native run has its own disposable vasc-*-qa identity. Normal saves and installed mods were not changed.

## Verified

23 tests in artifacts/vasc-video-polish-20260930/regressions-final.json pass. Cover responsive EN/DE binocular help, exact-map shallow stairs, lab order/size/lower bounds, native healing lifecycle, aimed six-second wish timing, reward allowlist, full bag, duplicates, cancelled choice, save boundaries, small-window bounds and rejected-frame allocation isolation; existing terrain/window/seat/battle/weather/mobile ordering tests also pass.

Native logs in the same artifact directory:

- native-final-review4.log: final lab, actual Mother heal, binocular opening, Mew in the real sky, small over-world choice, chosen Ultra Ball, repeated-A protection and save/reload, native Safari menu. Window retains an independent world frame to avoid a black loading view when the menu pauses first-person input.
- native-final-review3.log: three native first-person Viridian City ↔ Viridian Gym loops; all six transitions pass. This confirms the existing doorway flow, not a new doorway repair.
- native-comprehensive.log: six native Museum 1F↔2F, Tower 1F↔2F and Rocket B1F↔B2F stair transitions pass. The subsequent old Gym harness approaches its exit sideways and fails; the corrected north-to-south exit is covered by the successful separate three-loop run.
- native-exact-reviews.log: current Museum, Misty, Casino, bedroom and zoo captures; native animated Cobble Nidoking/Tauros with non-bind animation indices. First intro capture is before Nidoking becomes visible; menu capture proves the actual models, not every historical intro frame.
- native-ui-completion.log: Mewtwo moved away from overlapping Charmander stars and recaptured; existing CUSTOM SPRITES screen and actual RESCAN callback return correctly.

## Limits

No physical iOS/Android/Switch test and no FPS claim. The user has an iPhone/iPad, but no device was connected in the Mac's USB inventory. Superseded by the rc.4 review above: staged mobile scenery already includes semantic sky. No new 4K raster asset: scientific scrolls reuse the existing source with exact UV crops. No new volcano: explicitly declined because KASC already supplies it.

Historical rc.3 uncertainties were narrowed by the rc.4 follow-up above. Existing fountain attenuation is not presented as a repair of an unidentified sound. The full 37-point audit is docs/VIDEO_FEEDBACK_20260930.md. It distinguishes previously completed work, new candidate changes and external/uncertain acceptance.

## Packaging

Build with tools/build_local_candidate.py against the complete rc.2 ZIP. Verification checks Lua syntax, prepared model hashes, binary models/metrics, terrain asset sources, archive CRC, source equality and runtime/pack file receipts. See deliverables/VASC-3.0.61-rc.3-Local/verification.json after the build. This is a local experimental candidate; nothing pushed or published.

---

# VASC 3.0.60 public release verification

Promoted from the tested 3.0.60-rc.1 archive. Runtime Lua and assets are byte-identical; only release metadata, documentation and receipts change. The candidate report below describes the tests performed before promotion; statements that it was not yet published refer to that historical test stage.

# Pyro MAP / Sea Terrarium verification — local candidates

Bases: public VASC 3.0.59 and KASC 6.7.31. Isolated source branches and disposable LOVE identity; installed game, real saves and public release endpoints were not modified.

## Native desktop

LOVE 11.5 with the existing 0.1.90 QA host and both candidate sources. Real Blaine trainer battle: MAP provider, blaine_center shape, mid (400,256), Pokémon (376,256)/(424,256). Platform retained in battle furniture and excluded from whole-prop sight removal. Screenshots inspect court, lava and fountain phases. Starts from all four removed edge cells (16/17/32/33 at y=16) load onto safe walkable cells through native map recovery.

Route 20 surfing encounter: side and behind layouts render continuously (60 successful frames each), submerged actors, transparent water, open rim, neutral button, moves menu and attack; portrait touch layout additionally captured. Gorochu remains coloured with the selected HD art. The QA host lacks the user's optional HD human pack, so these screenshots show its fallback trainer artwork.

## Automated checks

- KASC route suite: 1,564 checks, including walkability, lava collision/water exclusion, links, leader/party, identity/rewards and music metadata.
- Sea suite: exact ocean/surf selection, land/Gen2/interior exclusions, both actor depths, trainer heights unchanged, finite geometry, bounded four-entry scene cache, no idle geometry rebuild, no sea dome, optional-water failure latch/release, one cached mesh/program, state restoration and partial-allocation cleanup.
- Blaine geometry suite: v1/v2/v3 ownership, unobstructed platform/bridge, fixed centre, four jets outside native lanes, stairs and OFF behavior. Blaine Terrarium alias remains intact.
- Existing Terrarium locations, zoom, light reuse, effect/dome failure, furniture receipts/light descriptors, battle camera continuity, arena request/query caches pass. Differential arena-result suite: 46 scenarios against public 3.0.59; unchanged unrelated maps and collision/height/camera invalidation.
- Water and existing Terrarium shader variants: 32 stages / 16 linked programs pass Khronos glslang, covering GL/GLES legacy and GLSL3. Native desktop water program compiles and renders.
- Build receipts separately verify every packaged Lua file, archive CRC, file hashes, complete public-baseline preservation, and VASC prepared-model checksums.

## Limits

No physical iOS/Android device run or mobile FPS claim. Desktop portrait touch preview is a layout check. Fountains reuse cached geometry with at most four draws and no full-scene reflection. Surfing chooses Sea; fishing from land keeps the existing scene. No publication was performed for these candidates.

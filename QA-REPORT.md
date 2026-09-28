# VASC 3.0.54 — Battle camera continuity verification

2026-09-28. Base: public VASC 3.0.53 (`a19a6396`). This standalone hotfix excludes local RC development. No save-format, native collision, gameplay-rule or model-asset changes. The 3.0.53 shadow implementation remains unchanged.

## Regression evidence
An Android support report from 3.0.53 records MAP on Route 1, then an `enemy-under-message` camera decline and court change, followed by `playerHero-under-fight`, a camera-seat timeout and automatic Terrarium selection. These are composition rejections, not evidence of GPU/camera allocation failure.

The native comparison injects the same persistent `playerHero-under-fight` verdict into the real camera evaluator while running the complete game and production renderer. The unmodified 3.0.53 package times out and switches to Terrarium; the candidate keeps rendering new MAP scenes beyond that timeout. The injection reproduces the control-flow failure, not the exact original phone's actor composition or GPU.

## Focused tests
Seven suites: battle_camera_continuity, hidden_actor_camera, live_battle_selection, battle_trainer_support, battle_controls_configuration, battle_timeout_reason and battle_native_retry.

Coverage includes each supported composition verdict; 300 consecutive continuity frames without repeating the complete rescue search; phase, deployment, orientation and manual-input changes; exact arena/battle ownership; provider errors/missing bounds; physical trainer support; explicit view switching and native retry ownership. Hard faults are not classified as composition limits.

## Native game verification
Isolated engine 0.3.2 host with the production mod sandbox, separate QA identities and generated test saves. Android policy on LÖVE 11.5/OpenGL and iOS policy on LÖVE 12/Metal, both on Apple M2. Route 1 at [15,30], Pidgeot versus Rattata, shadows enabled, ORAS HUD.

Persistent injected overlap: MAP continues producing fresh full scene frames; landscape-to-portrait rotation preserves MAP; attack selection and cancel work; explicit view cycling commits ARENA. Screenshots inspected. An overlap can intentionally remain visible rather than interrupting the battle or changing its selected environment. Attack completion is checked against the actual enemy Pokemon HP.

## Package and limits
The full ZIP is checked for CRC, Lua syntax, both embedded file-hash receipts and byte equality with the committed source. Targeted tests and the native continuity driver are run against the extracted final ZIP. Exact counts and SHA-256 are in verification.json.

This does not certify physical Android/iPhone hardware, all species/locations, sustained FPS or engine 0.3.26 device behavior. The correction is in the shared Gen 1 camera; Gen 2 camera logic is unchanged. Resource/renderer failures and unsupported physical placement retain recovery. Rollback: full public VASC 3.0.53 package.

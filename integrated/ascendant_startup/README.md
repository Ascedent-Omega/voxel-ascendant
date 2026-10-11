# Embedded Ascendant Entry Card · Omega continuation

One shared intro after confirmed New Game / Continue, after the cartridge boot cinema.
Embedded in both owners; game-scoped ownership deduplicates KASC + VASC. No external
startup mod is required. Supports the owners' six games: Red/Blue/Yellow/Gold/Silver/Crystal.
No platform gate: desktop, iOS, Android and NX use the same LOVE drawing/input path.

The native callback adopts the save only after the first displayed card frame.
Hidden gameplay/dialogue is paused. Gen1 ContinuePreparation and the real renderer
warm their existing region, geometry, light, shader and scenery resources. Gen2
Continue waits for the actual map/neighbor mesh receipts; Gen2 New Game preloads
native introduction and start-map textures, preserving Oak/name/clock/gender order.
No shadow World is created. Mandatory preparation can outlast the music; the final Omega logo
remains until readiness. Skip shortens only the animation.
Optional failed jobs are recorded and native validation dialogs retain priority.
A fresh entry reuses native caches without suppressing required readiness checks.

Eevee's static prepared pose lacked the poser quadruped walk. The atlas now bakes a
24-frame diagonal gait and 20-frame breathing/ear/tail idle. The independent animation
clock continues while native preparation completes.
Assets are released on completion/cancellation. Audio obeys SFX volume/splash mute.

Limits: initial engine/mod code loading before the menu is outside this hook.
Later travel or changed assets/settings may still require preparation. Gen3 is not
a supported generation of either parent mod. Physical mobile/NX validation remains
necessary; native Mac tests do not certify device-specific graphics/audio drivers.

The original Roxas2712 opening is retained. At 9.8 seconds the Lugia cry
plays; baked Cobblemon Lugia flies across and sweeps the original logo and
characters away. The continuation credit uses OASC's existing Omega Dias
wordmark and appears at the same time as the eye. Immediately after Lugia leaves, at 13.1 seconds the Eye Omega animation appears below the wordmark,
white on black, with the replacement caption “Omega Ascendant Team”. It runs
once, synchronized to the complete GameCube startup sound at its original tempo and pitch
(7.235918 seconds).
All cues share the SFX/mute/skip lifecycle and stop on cancellation.

`OmegaEye.lua` maps the GIF poses to measured GameCube audio onsets. The
eye/Omega/triangle switches and blink/zoom poses follow the melody; the final
logo and caption settle on the 4.327-second chord and hold through the decay.
The audible sample cursor drives the eye timing when audio is active; muted
devices fall back to the animation clock. Visible poses never rewind.
The draw shader inverts its
colors and the frame quads exclude the old caption. No live 3D renderer is
initialized by the intro. Asset source URLs and hashes are recorded in
`assets/omega-intro-sources.json`.

Native regression test: run a LOVE host whose main.lua loads
`tests/omega_intro_native_test.lua`, with INTRO_ROOT set to the mod source.
It covers asset/audio decoding, cue timing, hold deduplication, mute, skip
volume, slow-frame resynchronization, portrait drawing and resource cleanup.

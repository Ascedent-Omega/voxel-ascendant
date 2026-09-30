# Loading language fix — 3.0.61-rc.1

Local candidate based on public 3.0.60. The shared Ascendant startup progress now follows Universal's published boot language. English is the default, including an installed Universal mod booted in English. Pending language preferences take effect after restart. VASC's area, window and Continue loading companion uses its existing SetupLocale resolver.

Validation: loading_companion_test.lua passed in VASC (all wait kinds, EN/DE/default, native cover and cancellation); startup_language_test.lua passed in both repositories (both shared owners, late Universal exports, progress counter, single save adoption). Shared StartupCard.lua copies are identical. No changes to preload scheduling, animation duration, rendering quality, or save/gameplay logic.

Validation scope: Lua lifecycle/render-call fixtures and archive syntax/integrity checks; no new full in-game playthrough for this text-only patch.

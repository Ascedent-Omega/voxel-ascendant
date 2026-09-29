# RC46: remove repeated renderer admission parsing

The native map-entry trace showed 28 renderer compatibility lookups on entry to Route 16. Each lookup repeatedly parsed the same long supported-version range, including duplicate checks inside the same lookup. The change in Kanto Ascendant's `voxel_renderer_compat.lua` caches only the pure version/range boolean in a bounded 64-entry cache. Changed versions/ranges produce different keys.

Every lookup still discovers installed renderers, rejects ambiguous stacks, checks repository metadata, validates the live capability facade and probes rejection of private module names. No renderer handles or mutable capabilities are cached. Module access, exact-version adapters, native-only ownership and repository policy remain unchanged.

## Validation

`tests/renderer_version_cache_test.lua` in Kanto Ascendant passes with the actual host Semver implementation: 1,000 repeated lookups perform no repeated Semver parsing, while discovery and capability probes still run; live unload, changed policy, provenance mismatch, changed capabilities and private-authority exposure fail appropriately. Another 1,100 comparisons against the preceding implementation cover supported, unsupported, prerelease, malformed and cache-overflow cases.

Artifacts: `/Users/maarten/Documents/Recompile/artifacts/performance-map-entry-20260929` (`before`, `after`, `comparison.json`). Native `rc46_map_travel.lua` performs the same Celadon–Route 7–Celadon–Route 16–Celadon route with full Voxel buildings, night/rain, first person, 1710×958, muted isolated QA identity. Both runs pass. Exclude setup through frame 400, covered frames, and the diagnostic pathfinder frame plus its following delta frame.

| CPU measurement | Reference | Changed |
| --- | ---: | ---: |
| Renderer lookup maximum, summed within one frame | 6.68 ms | 0.17 ms |
| Renderer lookups total during sampled walk | 334.81 ms | 17.03 ms |
| Route 16 map initialization | 51.22 ms | 20.32 ms |
| Route 16 Wilds initialization | 35.66 ms | 13.25 ms |
| CPU frame p95 | 21.36 ms | 18.45 ms |
| Worst sampled CPU frame | 76.85 ms | 35.04 ms |
| Frames over 33.33 ms | 12 / 2567 | 2 / 2414 |

This is a single pair, not a global FPS or device guarantee. Sample lengths differ because timing affects movement. Directly targeted lookup time is the strongest evidence; other gains can include reduced garbage collection and run variation. The tracer wraps sprite creation, which can also cause the existing late style wrapper to reassert itself, so entity-creation timings are diagnostic rather than an uninstrumented benchmark.

Full visual settings remain active. The reported 4 FPS case is not yet reproduced. No release, commit or personal-save changes.

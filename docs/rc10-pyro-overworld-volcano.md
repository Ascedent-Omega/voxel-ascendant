# Pyro exterior correction — 30 September 2026

The reported rc.9 exterior used a brown voxel cliff that did not match Cinnabar's overworld volcano. The entrance now reuses `CinnabarVolcano.meshes` with an optional rigid rotation/uniform scale, a small low entrance cutout and the coastal apron omitted. The original caller's geometry and material order are unchanged. Bounds are calculated from each uploaded part, so both transformed and original views use correct culling boxes.

`BlaineVolcano.buildHorizon` owns the exact KASC foot profile only while Voxel Items is enabled. HorizonWall uses its existing preparation, cancellation, ready-cache and release lifecycle; no geometry is generated on door animation frames. The foreground keeps flat native ash beneath its rim to maintain terrain readiness. Lava, the cone, portal and ember props must stay outside all native walkable cells at actor height.

Evidence and accepted run are recorded at the top of QA-REPORT.md. Earlier draft runs in `artifacts/doors-volcano-20260930` found coastal trees/rocks, a small lava overhang, and overlong entrance supports intersecting playable cells; those draft views are not acceptance evidence. The final candidate omits the coastal props, sets back the cone and keeps the supports on native blocked cells.

The KASC compact court package is unchanged from rc.9 and remains a focused rc.3-based Pyro candidate, not an integration of ongoing Sevii work. Both matching packages are needed for the compact native court. No public publication or live-save edits.

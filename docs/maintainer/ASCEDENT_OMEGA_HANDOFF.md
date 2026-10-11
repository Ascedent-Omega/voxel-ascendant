# Ascedent-Omega: recoverable RC17 source handoff

Repository: https://github.com/Ascedent-Omega/voxel-ascendant

This branch restores the latest retained VASC source tree from the SHA256-verified 9 October NAS archive, original source commit `da36abc45f25087c44ee446402e29be77118c6fb`. Its parent is the organisation's current main. The tracked source is preserved; the manifest labels the archived paired RC17 package version `3.0.63-rc.17-sevii`. Missing ignored/static assets are supplied in the separate release ZIP, not added to Git.

This is an **archived review-candidate recovery snapshot**, not a newly certified release. The retained report recorded 59 component tests, 266 map types, zero source elevation seam/local mismatches and zero unresolved optional executed scopes. Physical Android and full settings/geometry review were still incomplete. New merged Johto panorama work lives in its own repository and is not silently overlaid here.

For collaboration, start from the current organisation remote, use a branch per Card/theme and a PR, fetch before edits, and pin every release to its own commit/tag. Never replace another maintainer's main or release tag. Merge resolution must be explicit, followed by relevant runtime checks.

Runtime rollback: deactivate the affected Card where available. Source rollback: revert this single handoff commit to its parent. Keep the original NAS archive unchanged.

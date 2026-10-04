# NowNest build 8 internal TestFlight handoff

The owner separately approved uploading the tested NOW-screen simplification
and icon correction as build 8 to the existing internal TestFlight group.
This receipt records the available evidence without treating upload as a
physical-device test or a public release.

- Candidate source: `532e90e` (build number 8 in both project configurations),
  following UI/icon commit `4a4de0f`. The build-number commit changes only
  `NowNest.xcodeproj/project.pbxproj`. The archive and IPA report bundle
  `com.foculoom.nownest`, version `0.1.0 (8)`, iPhone and iPad device families,
  and `ITSAppUsesNonExemptEncryption=false`.
- Local artifacts: `NowNest-build8-unsigned.xcarchive` and
  `NowNest-build8-export/NowNest.ipa` in the task workspace. IPA SHA-256:
  `1df0c1719d84fa443e3a16143b6a1bff2d4d5dc787499b5adfa4e92ca0122914`.
  DistributionSummary identifies existing Apple Distribution certificate
  SHA-1 `07289C6ED2EFEE978F396880B2E226EA54024354`, team `H8MJMBTFVP`,
  and the existing iOS Team Store provisioning profile UUID
  `a1b64f9b-b63d-4603-88e8-7167109ea401`. Strict `codesign --verify --deep
  --strict` passed with macOS trust-store access. No certificate or account
  permission was changed.
- Regression after the metadata edit: all 75 unit tests passed on iPhone 17 Pro
  simulator. The preceding UI/icon commit passed focused iPhone and iPad UI
  journeys and light/dark installed-icon inspection; no app source changed
  between that UI run and build 8 except the build number. The build-8 archive
  and signed export succeeded. Local logs are `build8-archive.log`,
  `build8-export.log`, `build8-upload.log`, and `/tmp/nownest-build8-units.log`.
- Xcode reported `Upload succeeded` and `Uploaded package is processing` on
  2026-10-04 at 03:23 UTC. Apple sent a TestFlight notification at
  03:24:54 UTC with subject “NowNest 0.1.0 (8) for iOS is now available to
  test”; its body says the notified tester can install the update in TestFlight
  on iOS 18 or later. This confirms availability to that tester. The older
  App Store Connect API-key path was unavailable and Safari's scripted page
  content was disabled, so this run did not independently read Apple's build
  UUID, processing-state field, or beta-group relationship. It does not claim
  a fresh group-membership API receipt.

Physical installation, comprehension of the simplified NOW screen, tinted
Home Screen appearance, VoiceOver, and live Apple Intelligence behavior are
still unverified. The prospective founder task check is in the
[build-7 usability review](build7-ux-icon-review.md). No merge, external
testing submission, or App Store release occurred.

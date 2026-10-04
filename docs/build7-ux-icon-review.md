# Build 7 usability and icon review — October 3, 2026

Status: the owner approved a bounded NOW-screen and icon correction after
this review, then separately approved an internal TestFlight upload. Build 8
was uploaded and the notified tester received Apple's ready-to-test email;
see [build-8 handoff](testflight-build8.md).
Baseline:
`edoworks/nownest@82115229487a75568aa0b8b89e619011ceb6573e`, internal
TestFlight `0.1.0 (7)`.

## Build-bound feedback

The authenticated [TestFlight Screenshot Feedback list](https://appstoreconnect.apple.com/teams/2807795a-81ff-48cd-850c-533c7a73898d/apps/6814614006/testflight/screenshots)
was reloaded and read on October 3, 2026 (Pacific time). It showed two newer
reports from Tosa Ojiru on **build 7**, iPhone 16 Pro Max, iOS 27.0.1. The
list gave relative ages, not exact submission timestamps:

1. Latest, displayed as **14 minutes ago**: “The app is a bit confusing to
   use. The usability needs work. There’s way too much going on and it seems
   cluttered and confusing. Act like a judge for an Apple design award and
   suggest improvements. It’s ok to redesign from the ground up!”
2. Preceding, displayed as **18 minutes ago**: “Related items should be
   collapsed. This is were Apple Intelligence can help. It’s 2026! Everything
   should be AI-native if feasible!”

The same list showed the older build-6 multiple-project complaint separately.
These are founder observations and requests, not a measured usability study or
proof of a specific implementation. The feedback-list text did not expose the
attached screenshot pixels; the current app and icon were reviewed separately
using simulator captures.

## Current screen and icon evidence

- The build-7 iPhone NOW capture (`project-iphone-visuals/6EE1F20E-0AFD-4C2C-9CDB-D8E4446F4330.png`, local task workspace) visibly repeats the
  active project name in the heading and inside the NOW card. Switch and Add
  project sit above a large three-field card; two large actions and persistent
  explanatory copy follow. This gives a concrete hierarchy and copy-density
  hypothesis behind “cluttered,” without proving which element confused the
  founder. The Imported ideas sheet capture shows origin, unfinished action,
  review, and assignment inline; it is legible but text-heavy.
- `AppIcon.appiconset/Contents.json` supplies five PNG sizes for iPhone, iPad,
  and marketing. It declares no dedicated dark or tinted appearance. Apple's
  [asset-catalog guide](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
  allows system-generated treatments, so missing custom variants alone is not
  a defect.
- Inspection of all five source PNGs found opaque near-white corner pixels,
  while the middle of each top edge is amber. The artwork itself contains a
  rounded mask/white exterior. Apple's [Icon Composer guide](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
  says to leave the canvas mask to the system; the [app-icon HIG](https://developer.apple.com/design/human-interface-guidelines/app-icons)
  describes a square layout that the system masks and a full-bleed background.
  This is a source-artwork correction worth considering. It is **not** evidence
  that users saw a white halo: no obvious halo appeared in the captured Home
  Screens.
- The installed icon was visually inspected at ordinary Home Screen size on
  iPhone 17 Pro and iPad Pro 11-inch (M5), iOS/iPadOS 26.5 simulators, in light
  and dark system appearance. The white mark remains recognizable and the
  orange tile retains contrast. At source size the diagonal has fine seams and
  arrow-like tips; their meaning is subjective. Dark system appearance kept
  the same orange icon in these simulator settings. Home Screen **tinted**
  appearance was not verified because `simctl ui` exposes light/dark interface
  appearance, not Home Screen icon tint controls. Physical-device appearance
  and user recognition are also unverified.
- Local screenshots, also saved to Library as images: `icon-iphone-current.png`,
  `icon-iphone-dark.png`, `icon-ipad-current.png`, `icon-ipad-dark.png`.
  Earlier tracked visual scenario evidence concerns in-app screens; an
  icon-specific visual receipt was not found in the inspected repo docs. This
  does not establish that the icon was *never* viewed before this review.

## Smallest proposed response and critique

**Icon proposal:** Preserve the orange tile and central white mark for one
bounded iteration. Recreate the background as full-bleed amber in every source
size, leaving rounding to the system; remove fine seams if they remain at
small sizes. Compare the resulting icon beside build 7 on light, dark, and
tinted Home Screens before deciding whether the metaphor needs a new concept.
This resolves the observed source-artwork issue without making an unsupported
claim that a new illustration will improve recognition.

**Usability proposal:** First test a smaller NOW-screen hierarchy: keep the
project name and visible Switch/Add controls in the header, but do not repeat
the project name inside the NOW card; retain outcome, next action, and the
primary Save for later action. Move persistent instructional copy behind an
accessible help affordance after first use. The immediate acceptance question
is whether a founder can identify current work, save an interruption, find
saved work, and switch back without prompting on a physical device. Apple's
2024 [Interaction award description of Crouton](https://www.apple.com/newsroom/2024/06/apple-announces-winners-of-the-2024-apple-design-awards/)
is a useful example of short steps that keep attention on the task; it is not
a scoring rubric or evidence NowNest would win an award.

**Related-item hypothesis:** Ask for examples of items the founder expects to
collapse before designing grouping. A possible later prototype is an
on-device, advisory “possible related ideas” suggestion within one project,
with explicit expand/assign controls, retained originals, and a manual path
when the model is unavailable. No automatic merge, deletion, or cross-project
reassignment follows from the build-7 feedback. Apple's
[generative-AI guidance](https://developer.apple.com/design/human-interface-guidelines/generative-ai)
supports clear control and recovery; “AI-native” does not require making
uncertain groupings silently.

Rubberduck critique: A ground-up redesign based on one broad report could
reintroduce the discoverability failures seen in earlier builds. Conversely,
only fixing icon corners would ignore the newer complaint about task flow.
Removing the header's Add control to reduce clutter would also hide a feature
the founder just requested. The smaller screen simplification is a testable
hypothesis, not a verified fix. A self-critique is not independent validation.

## Prospective founder check (recorded before a new build is uploaded)

**Hypothesis:** Removing the duplicate project field and default instructional
copy will make the NOW screen easier to understand without making project
switching, idea capture, or saved-work review harder to find. Correcting the
icon's pre-rounded white corners will preserve recognition while improving
its source artwork under system masks. The baseline is the build-7 founder
feedback and simulator captures listed above; the new build has not yet been
tested by the founder.

On the next physical-device check, give the founder these tasks without
coaching: identify the current project and next action, save an interruption,
find the saved item, and switch projects. Record whether each task succeeds,
where hesitation occurs, and whether the icon is recognized on light, dark,
and tinted Home Screens. A successful technical build or UI automation pass
does not establish user comprehension. Count the hierarchy hypothesis as
supported only if all four tasks succeed without prompting and the founder
reports no new ambiguity about project or saved-work controls. Any failed
task or new ambiguity calls for revisiting the layout. Count icon recognition
as supported only if the founder identifies it in all tested appearances;
simulator corner checks alone establish only asset correctness. This is one
founder's directional check, not a usability or commercial validation study.

The approved implementation keeps icon correction and NOW-screen
simplification separately reviewable. Verify the icon's pixel corners, asset
sizes, icon masking, and Home Screen previews at ordinary size, including
tinted mode on a device or supported UI path. Run focused iPhone/iPad UI tests
for Save, project switch, Imported ideas, and accessibility sizes. Preserve the
build-7 IPA and baseline screenshots for before/after comparison. This was the
pre-upload gate; the owner later approved the build-8 internal upload.

## Local implementation evidence (October 3, 2026)

- The normal NOW card shows Outcome and Next Action under a single project
  header with visible Switch/Add controls. The control variant remains a
  baseline. “How it works” retains the on-device review and reassurance copy
  behind an accessible disclosure. The saved-idea detail and model behavior
  were not changed.
- All five app-icon PNGs are opaque and have amber corner pixels; the white
  center mark was retained. Installed iPhone 17 Pro and iPad Pro 11-inch (M5)
  simulator Home Screens were inspected in light and dark appearance. The
  task workspace contains `nownest-final-iphone-light.png`,
  `nownest-final-iphone-dark.png`, `nownest-final-ipad-light.png`,
  `nownest-final-ipad-dark.png`, and `nownest-final-now-iphone.png`.
  Tinted Home Screen mode and physical-device recognition remain unverified.
- The full local unit suite passed: 75 tests, zero failures. Focused iPhone
  UI capture, variant, and visual tests passed except four suggestion-screen
  tests in the initial run: their helper assumed an off-screen button was
  immediately discoverable. After updating the helper to scroll to it, all
  four passed on rerun. Focused iPad tests for capture, project switch and
  relaunch, Imported ideas, and launch visuals passed. These deterministic
  tests and simulator captures do not validate on-device model output or
  founder comprehension.

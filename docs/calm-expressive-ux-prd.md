# NowNest Calm Expressive UX PRD

- Status: Sophie selected as the release-default treatment; broader release gates remain open
- Product: NowNest (`edoworks/nownest`)
- Baseline: `8d6f3b5`
- Prepared: 2026-09-21
- Release parent: `edoworks/factory` issue "Reference App 1: Apple submission and acceptance"

> Customer Zero amendment (2026-09-23): visual treatment is subordinate to the
> lifecycle contract in `customer-zero-prd.md`. A visually qualified build is not
> release-ready unless Park -> Resume -> Resolve and the seven-day dogfood gate pass.
> Founder-feedback amendment (2026-09-23): Sophie supersedes the provisional
> no-selection state as the release default, with Quiet Mode preserving a fully
> functional character-free treatment. This selection does not authorize release.
> Build-4 feedback amendment (2026-09-24): issue #59 authorizes one optional,
> explicitly requested on-device starting-action suggestion in the saved-idea
> detail. Capture remains immediate and the complete manual workflow remains the
> fallback. The source implementation merged at `66f7b4a`; this amendment does
> not authorize a replacement build, upload, or release.

Tracking:

- [Redesign map](https://github.com/edoworks/factory/issues/28)
- [Chunk A: prototype visual system](https://github.com/edoworks/factory/issues/29)
- [Chunk B: Home, Capture, success, and Quiet Mode](https://github.com/edoworks/factory/issues/30)
- [Chunk C: Review and accessibility qualification](https://github.com/edoworks/factory/issues/33)
- [Chunk D: human comparison and selection](https://github.com/edoworks/factory/issues/32)
- [Build-4 on-device suggestion](https://github.com/edoworks/factory/issues/59)

## 1. Outcome

Give NowNest a recognizable visual language without weakening its deliberately
small interruption-recovery loop:

```text
see NOW -> capture idea -> park locally -> confirm -> resume NOW
```

The immediate deliverable is three comparable, fully functional treatments of
that same loop:

1. `control`: the current interface, preserved as the comparison baseline.
2. `expressive`: calm visual identity without a character.
3. `sophie`: the expressive treatment with Sophie as an optional transition
   character.

The initial selection gate required the task-based human comparison in section
12. The later owner disposition recorded in
`evidence/testflight/founder-feedback-2026-09-23.json` selected Sophie as the
release default and is implemented in the current source. Prototype completion
and treatment selection do not authorize upload, submission, commercialization,
application rename, or trademark adoption.

## 2. Product Decision

### Confirmed

- The current information architecture is a strong low-distraction foundation.
- The interface is visually generic: mostly standard SwiftUI surfaces, system
  symbols, black controls, and a beige gradient.
- "ADHD-friendly" must not be treated as a request for continuous stimulation.
- The design direction is **calm expressiveness**: identity at meaningful
  transitions, followed by a return to visual rest.
- Sophie is a candidate "nest keeper," not a virtual-pet subsystem.

### Default audience

Design for adults using a general productivity tool, with particular attention
to people who experience distractibility, task-switching cost, or cognitive
overload. Do not claim to diagnose, treat, or medically benefit ADHD. Do not
use childish, scolding, needy, or diagnostic language.

### Hypothesis

A distinctive but restrained treatment can improve recognition, confidence,
and delight without increasing capture-to-resume time or reducing next-action
recall. Sophie is worth advancing only if she improves satisfaction without
hurting those measures.

## 3. Non-goals

- No feeds, dashboards, streaks, points, currencies, collections, levels, or
  routine confetti.
- No timers, reminders, notifications, accounts, analytics, cloud sync,
  network access, or background work. On-device Foundation Models may run only
  after an explicit request in the saved-idea detail.
- No pet care, hunger, mood, obligation, punishment, or random interruption.
- No change to the meaning of `NOW` and `PARKED`; generated text is an editable
  suggestion and never overwrites the original thought or activates itself.
- No new navigation destinations except a lightweight appearance/settings
  control if needed for Quiet Mode.
- No third-party packages, fonts, remote images, or generated-at-runtime assets.
- No application rename, bundle identifier change, TestFlight upload, App Store
  submission, publication, or trademark adoption.

## 4. Success And Guardrails

### Machine-verifiable

- All existing unit and UI tests continue to pass in `control`.
- All six baseline UI journeys pass in every variant on iPhone and iPad.
- `control` retains the baseline layout and copy except for changes needed to
  select a debug variant.
- Every functional control remains available with Quiet Mode and Reduce Motion.
- No state is communicated by color, motion, or Sophie alone.
- Dynamic Type does not clip or hide the next action, capture field, Park
  control, confirmation, or review content at accessibility sizes.
- The app remains offline and adds no entitlements or packages.
- Suggestion generation never delays Save, never blocks Resume, and exposes a
  complete manual fallback when unavailable or failed.
- Saved, preparing, ready, unavailable, and failed states use explicit text and
  controls rather than color or animation alone.

### Human-verifiable

- A participant can identify the next action without instruction.
- Parking an idea does not obscure or mutate the current NOW context.
- The return prompt is immediately understood.
- VoiceOver traversal on both physical form factors presents task content before
  decorative identity and follows the order in section 10.
- Sophie is described as supportive or neutral, not distracting, childish,
  guilt-inducing, or demanding.
- The treatment works on physical iPhone and iPad in light and dark appearance.

### Failure conditions

Do not advance Sophie if she slows or distracts from capture/resumption, feels
infantilizing to the target audience, or performs no better than the simpler
expressive treatment. Revert decorative treatments that weaken contrast,
hierarchy, VoiceOver, Dynamic Type, or reduced-motion behavior.

## 5. Variant Contract

Add a small internal `VisualVariant` type with `control`, `expressive`, and
`sophie` cases. Parse the UI-test/debug launch argument:

```text
-visual-variant control|expressive|sophie
-quiet-mode enabled|disabled
```

Requirements:

- Release builds use `sophie` when the variant option is absent or unsupported,
  reflecting the recorded production-treatment selection.
- Variant selection is dependency-injected through SwiftUI environment state;
  feature views must not repeatedly inspect `ProcessInfo`.
- Variants alter presentation and copy only. Persistence and actions use the
  existing store paths.
- UI tests launch each variant explicitly. No test may rely on a developer
  default.
- Parse each option as an argument/value pair. A missing value, duplicate
  option, or unsupported value is invalid test configuration and must fail fast
  in DEBUG/UI-test runs. In a release run, invalid or absent variant input uses
  `sophie`; invalid Quiet Mode input is ignored and the stored preference is
  used.
- A valid `-quiet-mode` launch override takes precedence over `@AppStorage` for
  that process but does not mutate the stored preference.

Suggested files:

```text
NowNest/Design/VisualVariant.swift
NowNest/Design/NowNestTheme.swift
NowNest/Design/SophieMark.swift
NowNest/Design/NestSurface.swift
```

Keep the implementation smaller if the same contract can be expressed clearly
with fewer files.

## 6. Visual System

Use named semantic tokens rather than raw colors inside feature views.
Implement light and dark appearances in the asset catalog or an equivalent
centralized theme.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `canvas` | `#FFF8EA` | `#18140F` | App background |
| `surface` | `#FFFDF7` | `#242019` | NOW and sheet surfaces |
| `surfaceRaised` | `#F7E8C8` | `#342A1E` | Notes and secondary emphasis |
| `ink` | `#28231D` | `#FFF8EA` | Primary text and controls |
| `inkMuted` | `#6F665B` | `#C9BDAE` | Supporting text |
| `honey` | `#D99324` | `#F2B84B` | Primary action and focus accent |
| `ginger` | `#B95F35` | `#E8885B` | Sophie and warm accent |
| `sage` | `#617A64` | `#92B697` | Safely parked/success state |
| `danger` | system red | system red | Destructive action only |

Token rules:

- Confirm contrast against the actual paired backgrounds. Target WCAG AA for
  normal text and do not assume the hex table alone proves compliance.
- Use `ink` for primary text; never use honey or ginger for body copy.
- Keep system red and native destructive semantics for deletion.
- Use color plus text/icon/shape for success and state.
- Preserve system typography and Dynamic Type. Identity comes from hierarchy,
  spacing, shape, illustration, and voice, not a custom font.
- Base spacing unit is 4 points. Prefer 8, 12, 16, 24, and 32 point gaps.
- Primary surfaces use 24-point corners; paper notes use 16-point corners.
- Shadows must be subtle, optional in dark mode, and never the only boundary.

## 7. Screen Treatments

### Home / NOW

All variants retain this content order:

1. NOW context
2. Park action
3. Brief reassurance

`expressive`:

- Replace the generic gradient/card combination with `canvas` and a quiet
  `surface` NOW card.
- Make `NEXT ACTION` the strongest text on the screen.
- Use a small nest/paper motif as a noninteractive accent.
- Use honey for the Park action while maintaining sufficient text contrast.
- On iPad, cap readable width and use surrounding space intentionally; do not
  add columns or unrelated content merely to fill the display.

`sophie` adds:

- A small static Sophie mark adjacent to, but visually quieter than, the NOW
  heading.
- Sophie must not sit between the user and the next action or Park control.
- Sophie is accessibility-hidden when decorative.

### Capture

- Keep focus in the idea field and keep the Park action one step away.
- Retain the explicit return target: `After parking, return to: [next action]`.
- Use a paper-note surface, but retain native text-field behavior and focus.
- Sophie may appear as a small static guard beside the return target. She must
  not animate while the user types.

### Success

`control` keeps the current message.

`expressive` uses a brief sage-accented state and this structure:

```text
Tucked away. Back to: [next action].
```

`sophie` uses:

```text
Sophie tucked it away. Back to: [next action].
```

Motion rules:

- One transition, at most 450 ms, initiated only by a successful Park action.
- The animation may tuck a note or move a paw/tail once. No loop and no sound.
- With Reduce Motion, replace movement with an immediate pose/color/state
  change while keeping the same confirmation text.
- Confirmation remains visible long enough to read and preserves the existing
  accessibility identifier `parkConfirmation`.

### Review

- Present parked ideas as restrained paper notes or nest contents while
  retaining chronological order, `PARKED` text, timestamp, and native deletion.
- Sophie may appear only in the empty state or header, not on every row.
- Preserve the delete confirmation and rollback behavior.

## 8. Sophie Contract

Build Sophie from local vector SwiftUI shapes or checked-in original assets.
Do not copy a commercial mascot or fetch art at runtime.

Sophie is:

- warm, observant, quiet, and competent;
- a keeper of parked thoughts;
- secondary to the current next action;
- present at transitions, not continuously active.

Sophie never:

- asks for care or attention;
- expresses disappointment, urgency, hunger, sadness, or punishment;
- celebrates routine actions excessively;
- diagnoses or refers to the user as having ADHD;
- blocks a control, carries required information, or becomes the only success
  signal.

Minimum poses for the prototype:

1. `resting`: static mark on Home.
2. `guarding`: static mark in Capture.
3. `tucked`: single success pose or reduced-motion replacement.

Do not expand the character system before the human comparison passes.

## 9. Quiet Mode

Quiet Mode removes character copy, Sophie imagery, and decorative motion while
preserving the selected variant's functional layout and all task information.

"Decorative motion" includes Sophie poses, tucked-note or substitute
illustrations, success-transition animation, and animated dismissal. Quiet
Mode uses immediate state replacement for those elements even when Reduce
Motion is off. Functional system transitions may remain only when they carry
task state and do not reintroduce character or celebratory motion.

- Store the preference locally with `@AppStorage("quietModeEnabled")`.
- Expose a clearly labeled `Quiet Mode` toggle from the existing Actions menu
  or a small settings sheet. Do not add a tab bar.
- Default Quiet Mode to off in `sophie`; it may be a no-op for `control`.
- When enabled in `sophie`, use the `expressive` confirmation copy and omit all
  Sophie marks.
- Add a UI-test launch override so the quiet state is deterministic.
- Use the exact `-quiet-mode enabled|disabled` argument in section 5. Every UI
  test supplies one value, so `UserDefaults` cannot leak state between tests.
- Quiet Mode is not a substitute for Reduce Motion; both must work together.
- Hide the Quiet Mode control in `control`; the baseline must not gain a no-op
  menu item.
- Keep the presentation policy test-visible without exposing decorative art to
  VoiceOver. Tests must assert absent Sophie imagery/copy and absent decorative
  transition state, not infer suppression from a test name or screenshot.
- Include separate negative or mutation guards demonstrating that reintroducing
  Sophie imagery/copy and reintroducing each decorative-motion path make Quiet
  Mode verification fail.

## 10. Accessibility Contract

- Preserve all existing accessibility identifiers used by UI tests.
- Add identifiers only where needed to assert variant and Quiet Mode state.
- Combine decorative subviews into logical reading groups where appropriate.
- Hide purely decorative Sophie and nest marks from accessibility.
- Give meaningful labels to any interactive appearance controls.
- Validate portrait iPhone and iPad at default and accessibility text sizes.
- Validate light/dark appearance, Increase Contrast, Differentiate Without
  Color, Reduce Transparency, and Reduce Motion.
- Do not encode `PARKED`, errors, selection, or success through color alone.
- Do not auto-dismiss content before VoiceOver can discover the result. If the
  existing three-second confirmation proves too short under VoiceOver, retain
  it until focus moves or use an accessibility announcement plus a persistent
  visual state. Record the chosen behavior in tests.

Use this qualification checklist and record each row as pass/fail/not run with
source revision, mode, device, OS, variant, command, timestamp, evidence path,
direct pass condition, and notes. A row without matching execution evidence is
`NOT_RUN`; source inspection, ordinary-mode tests, and screenshots do not prove
an accessibility mode was exercised.

| Check | Where | Pass condition |
| --- | --- | --- |
| Dynamic Type | iPhone and iPad simulator; default and largest Accessibility Size | Required content and controls remain visible, readable, reachable, and non-overlapping without horizontal scrolling. |
| VoiceOver order | Physical iPhone and iPad | NOW heading, Project, Outcome, Next Action, Park action, reassurance, then Actions; decorative art is absent from the rotor/order. Capture reads heading, field, return target, then controls. Success is announced once. |
| Text contrast | Accessibility Inspector against every token pairing | At least 4.5:1 for normal text and 3:1 for large text. |
| Non-text contrast | Accessibility Inspector/manual boundary inspection | At least 3:1 for essential controls, focus, and component boundaries. |
| Differentiate Without Color | Simulator | PARKED, success, errors, and selection retain text/icon/shape cues. |
| Increase Contrast | Simulator | Content remains readable and hierarchy remains intact. |
| Reduce Transparency | Simulator | No required boundary or text disappears. |
| Reduce Motion | Simulator and physical devices | No tuck/paw/tail movement; immediate state replacement and the same confirmation information remain. |
| Light/dark appearance | Simulator and physical devices | No clipping, illegible pairings, unintended pure-black blocks, or lost boundaries. |

Dynamic Type, contrast, and non-color checks are machine/operator-verifiable in
Chunk C. VoiceOver order and the physical-device rows are human checks in Chunk
D; Chunk C must mark them pending rather than infer a pass from screenshots.

## 11. Automated Verification

### Unit tests

Add focused tests for:

- launch-argument parsing, DEBUG invalid-input failure, and release fallback;
- Quiet Mode presentation policy;
- variant-specific confirmation copy;
- Sophie suppression under Quiet Mode;
- no changes to existing normalization and persistence behavior.

Keep presentation policy in small pure types/functions where that makes these
tests deterministic. Do not move SwiftData behavior into the theme layer.

### UI tests

Retain the six current journeys and their screenshot checkpoints. Add a helper
that launches an explicit visual variant. At minimum:

- Run all six existing journeys in every variant on both simulator families.
- Assert the next action is unchanged after capture in every variant.
- Capture retained `launch-now`, `capture-confirmed`, and `review-parked`
  screenshots for each prototype using variant-qualified attachment names.
- Assert Quiet Mode removes Sophie without removing the Park control, next
  action, return target, confirmation, or parked ideas.
- Assert exact confirmation and return-target copy. Provide a test-visible
  presentation-state assertion or deterministic comparison for decorative
  imagery and motion; screenshot capture alone is not an assertion.

Required matrix (`R` means required):

| Existing UI test | control iPhone/iPad | expressive iPhone/iPad | sophie iPhone/iPad |
| --- | --- | --- | --- |
| `testNowIsVisibleAtLaunch` | R/R | R/R | R/R |
| `testCaptureReturnsToUnchangedNow` | R/R | R/R | R/R |
| `testReviewShowsOnlyTheIdeaJustParked` | R/R | R/R | R/R |
| `testParkedIdeaSurvivesAppRelaunch` | R/R | R/R | R/R |
| `testExplicitNowEditChangesOnlyAfterSave` | R/R | R/R | R/R |
| `testReviewDeletionRemovesSelectedIdeaAfterConfirmation` | R/R | R/R | R/R |

Add one Sophie Quiet Mode test on both simulator families. Test helpers must
always pass both `-visual-variant` and `-quiet-mode`; persistence relaunches must
reuse the same values.

The required journey matrix contains 36 cells (six journeys x three variants x
two device families). A passing count for a smaller suite does not satisfy this
contract. Each retained result identifies source revision, resolved simulator
and OS, completed test count, result bundle, and any incomplete or timed-out
cells.

### Build matrix

Chunks A-C use direct no-archive Xcode commands. Use available simulator names
that match these families, record the exact resolved destinations, and always
write a result bundle outside the repository before producing the durable
summary from section 14:

```bash
xcodegen generate
xcodebuild test -project NowNest.xcodeproj -scheme NowNest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath /tmp/NowNest-iPhone.xcresult
xcodebuild test -project NowNest.xcodeproj -scheme NowNest -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)' -resultBundlePath /tmp/NowNest-iPad.xcresult
xcodebuild analyze -project NowNest.xcodeproj -scheme NowNest -destination 'generic/platform=iOS Simulator'
```

Run the matrix on:

- an iPhone simulator;
- an iPad simulator.

Physical-device validation follows only after simulator verification and must
not trigger a TestFlight upload without separate explicit authorization.

The pinned factory verifier is a later release-gate check because it creates an
unsigned archive. See section 19. Do not run it during Chunks A-C without
explicit archive authorization.

### Static regression check

Review the final diff for new occurrences of networking APIs, analytics SDKs,
notification/background capabilities, third-party dependencies, and model
schema changes. Any occurrence blocks this scope pending review.

## 12. Human Comparison

This is a required decision gate, not optional polish. Use the same seeded NOW
context and parked-idea content for every variant. Counterbalance presentation
order when testing more than one participant.

Chunk D is an explicit human handoff. The authorized operator is the owner or a
facilitator the owner names in `edoworks/factory#32`. An implementation agent
may prepare a local build, reset fixtures, generate a blank observation record,
and summarize observations supplied or approved by that operator. It may not
recruit or impersonate participants, grant consent, deploy to a device without
authority, fabricate observations, sign the decision, or change the production
default.

The original plan required at least five adult participants before selecting
Sophie. The owner dispositions recorded on 2026-09-23 supersede that requirement
only for the current qualification-build default and public visual treatment.
They do not establish preference, usefulness, external validation, or commercial
fitness. Representative external validation remains a commercialization gate
and must report the limitations of selecting the current default before that
comparison. When running the planned comparison, at least three participants
should self-identify as regularly experiencing distractibility or task-switching
cost; do not require or record a diagnosis.

Validate both physical form factors: at least two participants use the iPhone
and at least two use the iPad. The human operator also completes the physical
accessibility checklist on both devices.

Use this exact fixture for every variant:

```text
Project: Prepare weekly plan
Outcome: Know the three priorities for Monday
Next Action: Write the first priority
Supplied interruption: Compare standing desks
Deliberate distraction: after immediate recall is recorded, the facilitator
asks the participant to count backward aloud from 10, then asks again what they
should resume.
```

Prepare each run on a dedicated test install: delete/reinstall or use the
approved local reset path, edit NOW to the three fixture values, and delete all
parked ideas before handing the device to the participant. Do not use a device
containing production or personal data.

Time from the first tap on `Park an idea` until the participant first correctly
states or resumes `Write the first priority`; this is the immediate
capture-to-resume measure. After recording it, ask the participant to count
backward aloud from 10, then record post-distraction recall as a separate
correct/incorrect observation. Use one stopwatch method for all variants.
Rotate variant order across participants; record the order used.

### Tasks

1. Identify the current next action.
2. Park a supplied interruption.
3. State what to resume immediately after parking.
4. Count backward from 10, then state the next action again.
5. Find and review the parked idea.

### Record per variant

- completion and errors;
- capture-to-resume time;
- correct recall of the next action;
- perceived effort on a consistent 1-5 scale;
- delight/satisfaction on a consistent 1-5 scale;
- distraction on a consistent 1-5 scale;
- open response: supportive, neutral, childish, demanding, or other;
- observed clipping, readability, interaction, motion, or accessibility defects.

Do not infer clinical effectiveness. With a small formative sample, report raw
observations and uncertainty rather than statistical significance.

For every scale, `1` means lowest/least and `5` means highest/most. Show those
anchors to each participant and do not reverse scoring between variants.

### Selection rule

The rules below remain the evaluation framework for future representative
external validation and any commercial preference claim. The 2026-09-23 owner
dispositions supersede their timing, metric, participant-minimum, and
commit-linked approval prerequisites only for the current qualification-build
default and public treatment. That exception does not count as passing these
rules and must be disclosed in later comparison evidence.

- Reject a treatment if any participant cannot complete the loop or recall the
  next action when they succeeded in `control`.
- Reject Sophie if two or more participants call her childish, demanding, or
  distracting, or if her median distraction score is at least one point worse
  than `expressive` on the 1-5 scale.
- Treat median capture-to-resume time as equivalent when it differs from the
  faster treatment by no more than the greater of one second or 10%.
- Select Sophie only when she passes the rejection rules and her median
  satisfaction is at least one point higher than `expressive`, and she is
  timing-equivalent to the fastest passing treatment.
- Select `expressive` when it passes the rejection rules, is timing-equivalent
  to the fastest passing treatment, and its median satisfaction is at least one
  point higher than `control`.
- Prefer `expressive` over Sophie when both qualify but Sophie does not meet her
  one-point satisfaction advantage.
- Keep `control` when neither candidate meets these explicit selection rules.
- Record the decision, evidence location, participants/audience limitations,
  and dissenting observations before changing the release default.

Write the decision to `evidence/ux/decision-YYYY-MM-DD.md` using these headings:
`Operator and authority`, `Participants and limitations`, `Fixture and order`,
`Raw observations`, `Accessibility observations`, `Selection-rule evaluation`,
`Decision`, `Dissent and unknowns`, and `Owner approval`. Approval is the
owner's dated statement in the record or an authenticated comment on
`edoworks/factory#32`
linking the exact commit. Absence of that approval means no production change.

## 13. Implementation Chunks

Each chunk must end in a reviewable commit and pass its listed verification.
Do not combine chunks if doing so hides a failing intermediate state.

### Chunk A: Prototype infrastructure and visual system

- Add `VisualVariant`, launch parsing, centralized semantic tokens, reusable
  surfaces, and the local Sophie mark/poses.
- Add pure unit tests for variant policy and confirmation copy.
- Keep the release parser fallback aligned with the recorded default; every UI test passes an
  explicit variant and Quiet Mode value.
- Verification: unit tests, control launch screenshot, light/dark build.

### Chunk B: Home, Capture, and success treatments

- Apply `expressive` and `sophie` treatments without changing the action path.
- Add Quiet Mode and reduced-motion behavior.
- Extend UI tests for launch, capture, unchanged NOW, variant confirmation, and
  Quiet Mode.
- Verification: relevant tests on iPhone and iPad simulators plus retained
  screenshots.

### Chunk C: Review and accessibility completion

- Apply review/empty-state treatment while preserving deletion semantics.
- Complete the simulator/operator accessibility rows and prepare the exact
  VoiceOver/physical checklist for the human operator.
- Run the full matrix in section 11 and the simulator/operator rows in section
  10. Mark physical VoiceOver checks pending for Chunk D.
- Verification: no-archive simulator matrix, static regression check,
  accessibility checklist, and screenshot review. The full factory verifier is
  deferred until archive authority is explicit.

### Chunk D: Human comparison and external-validation decision

- The named human operator runs section 12 and the pending physical
  accessibility rows on iPhone and iPad; the agent prepares and summarizes.
- Record raw results and the selection rule outcome.
- Only after the result is approved, remove prototype-only branching that is no
  longer needed. The current qualification default remains Sophie under the
  recorded owner exception; comparison determines whether evidence supports
  retaining it for later commercial decisions.
- Verification: owner-approved decision record linked from
  `edoworks/factory#32`. If the
  minimum participant rule is unmet, record formative results without claiming
  external validation or commercial preference.

## 14. Required Evidence Per Chunk

Every implementation issue or pull request must state:

- baseline and resulting commit;
- exact files changed;
- test commands and result-bundle paths;
- simulator/device model and OS;
- screenshot attachment or durable artifact paths;
- accessibility modes checked;
- known failures and untested claims;
- confirmation that release/publication authority boundaries were preserved.

TestFlight evidence is build-bound. For each build, record the source revision,
version/build, Apple build identifier, processing and beta state, observation
date, and either a sanitized authenticated tester-feedback reference or
`NO_DURABLE_FEEDBACK`. App Store Connect platform feedback, including export-
compliance or metadata guidance, is recorded separately and never represented
as tester feedback. Feedback for an earlier revision does not qualify a later
build, and absence of durable feedback does not mean "no issues found."

Run authenticated feedback freshness checks both before a feedback-driven or
release-candidate increment is scoped and immediately before it closes. The
check covers TestFlight screenshot feedback, TestFlight crashes, App Store
customer reviews, and App Store version state when applicable. Record sanitized
watermarks, endpoint/filter identity, exhausted page counts, and per-build
submission counts. A credential, API, pagination, or coverage failure blocks
closeout; it is not evidence that feedback is absent. If a newer material
submission is present, reconcile its disposition and acceptance test before
closure. This two-checkpoint rule is effective after issue #59; its earlier App
Store intake state remains explicitly `NOT_RUN` rather than retroactively
inferred.

Store durable summaries under `evidence/ux/<chunk>-YYYY-MM-DD.json` and
representative PNGs under `evidence/ux/screenshots/<commit>/`. The JSON must
include schema version, baseline/result commit, commands, resolved destinations,
test counts, pass/fail status, accessibility checklist results, raw `.xcresult`
path and SHA-256 when retained locally, screenshot paths, known gaps, and the
tracking issue. Do not commit `.xcresult` bundles. Attach or link additional
logs in the tracking issue when needed; the checked-in summary and PNGs must be
sufficient to resume work after loss of the original machine.

Never mark a human or device check complete based only on automation.

The subject revision identifies the app source and build under test. The
evidence revision identifies the later commit containing its durable summary;
these revisions are intentionally distinct and both are required.

## 15. Public Surface Contract

Product-owned public pages must look and sound like the validated qualification
build rather than a generic documentation template. Apply the visual system in
section 6 to the NowNest home, support, privacy, and terms pages:

- use `canvas`, `surface`, `surfaceRaised`, `ink`, `inkMuted`, `honey`,
  `ginger`, and `sage` as semantic web tokens in light and dark appearances;
- preserve system typography and build identity through hierarchy, spacing,
  rounded 24-point primary surfaces, rounded 16-point note surfaces, and local
  illustration rather than a custom display typeface;
- use checked-in original Sophie, nest, and tucked-note artwork instead of
  emoji or remotely fetched assets;
- keep Sophie small, static, secondary to the task, and hidden from assistive
  technology when decorative; public pages must not turn her into a pet,
  spokesperson, interactive control, or source of required information;
- use honey for primary emphasis, ginger for identity, and sage only for safe
  saved/success states; never use an accent color for body copy;
- retain visible boundaries without relying on shadows and honor dark and
  reduced-motion preferences without introducing decorative animation.

Web acceptance requires WCAG AA contrast measurements for every rendered token
pair, keyboard-operable controls with visible focus, semantic headings and
landmarks, no information conveyed by color alone, and readable reflow without
horizontal scrolling at 200% zoom and a 320 CSS-pixel viewport. Decorative
artwork has empty alternative text or is excluded from the accessibility tree.

Public product language uses `Save for later`, `saved idea`, `Resume`, `Done`,
`Save again`, and `Abandon`. `PARKED`, `park`, and `re-park` remain acceptable
only in internal models, historical evidence, or implementation documentation.
The public headline is `Save it for later. Return to now.` Copy should name the
human job first: save an interruption without losing the current place, then
return later with the context needed to begin. Do not use diagnostic language,
promise an absence of distraction, or describe the product as clinically
effective.

Every public page must state the lifecycle truth in plain language: NowNest is
in qualification and is not currently available for public download. Customer
Zero usefulness, repeated dogfood use, exact-candidate validation, a build-bound
feedback receipt or `NO_DURABLE_FEEDBACK`, representative external validation,
willingness-to-pay evidence, and Apple distribution remain separate gates;
Apple acceptance must not be presented as the only unfinished step. Portfolio
placement uses an `In qualification` status and must not imply release, revenue,
customer validation, or commercial proof.

Support and legal copy must match implemented behavior and product-identity
evidence:

- saved ideas can be marked Done, saved again, or Abandoned; do not claim an
  individual hard-delete path unless a validated build provides one;
- removing the app is the available whole-store removal path, subject to
  operating-system offload, backup, and restore behavior; do not promise
  irreversible deletion without direct lifecycle evidence;
- `NowNest` is a provisional public name pending clearance; do not claim
  trademark registration, adoption, or ownership;
- privacy statements apply to the validated qualification build and keep
  website hosting and support-message processing separate from app behavior.

The Edoworks homepage should feature NowNest as qualification-stage work, and
the portfolio should give it a complete product card rather than a lesser text
record. Discovery prominence does not change lifecycle status or authorize a
download.

Public use of the provisional `NowNest` identifier requires explicit current
owner publication authority and must not be represented as product-name or
trademark adoption. Commercial name adoption still requires `CLEARED` identity
evidence. Before either condition is met, implementation remains non-public
staging. The 2026-09-23 owner direction authorizes the website-alignment change
described here but does not authorize trademark adoption or commercialization.

## 16. Authority And Privacy

- All content and preferences remain on-device.
- Do not add telemetry to answer prototype questions. Human comparison notes
  must be consented, minimized, and contain no unnecessary personal or health
  information.
- This approved handoff authorizes local simulator builds and tests for Chunks
  A-C. Physical-device deployment, any archive, TestFlight upload, App Store
  submission, public visibility change, or product-name adoption requires
  separate explicit human authority.
- `NowNest` remains a provisional public name pending the checks in
  `evidence/product-identity-candidate-2026-09-21.json`.

## 17. Research Basis And Limits

Primary guidance, retrieved 2026-09-21:

- [W3C Making Content Usable for People with Cognitive and Learning Disabilities](https://www.w3.org/TR/coga-usable/)
- [W3C Understanding Success Criterion 2.3.3: Animation from Interactions](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html)
- [Apple Accessibility: Cognitive](https://developer.apple.com/documentation/accessibility/cognitive)

Secondary reviews, retrieved 2026-09-21:

- [Lumsden et al. (2016), Gamification of Cognitive Assessment and Cognitive Training](https://doi.org/10.2196/games.5888)
- [Wiley et al. (2021), Digital Games for Attention](https://pmc.ncbi.nlm.nih.gov/articles/PMC8386381/)
- [Lau et al. (2017), Serious Games for Mental Health](https://pmc.ncbi.nlm.nih.gov/articles/PMC5241302/)

Pattern references such as Finch, Forest, and Tiimo show that companion,
growth, and visual-structure patterns are deployed in products. They do not
prove that those patterns will help NowNest. Evidence for gamification is mixed
and is not specific to this interruption-capture workflow. Effectiveness and
preference remain product hypotheses that require the comparison above.

## 18. Definition Of Done

The redesign program is complete only when:

1. Chunks A-C satisfy all automated and assigned simulator/operator
   accessibility criteria; human physical/VoiceOver rows are completed in
   Chunk D.
2. The three treatments have comparable retained evidence.
3. Chunk D records the human comparison and selection decision.
4. The selected treatment is integrated without changing persistence or scope.
5. Factory release gates are rerun where the source change invalidates earlier
   evidence.
6. Any upload, submission, or publication is separately authorized and
   recorded.

Until then, describe status precisely as "prototype implemented," "automated
validation complete," "awaiting human comparison," or "treatment selected;
qualification incomplete," not "redesign complete."

## 19. Fresh-machine Bootstrap

The repository is the implementation source of truth. A new operator must not
need this conversation or the machine that produced the PRD.

Required toolchain:

- macOS 26.x and Xcode 26.x; baseline validation used Xcode 26.6.
- Swift 6.x and Git.
- XcodeGen; baseline project generation used 2.44.1.

Bootstrap:

```bash
git clone https://github.com/edoworks/nownest.git
cd nownest
xcodebuild -version
xcodegen --version
xcodegen generate
git diff --exit-code -- NowNest.xcodeproj/project.pbxproj
```

If XcodeGen is absent, install it using its official installation instructions,
record the installed version, and then run the commands above. A version other
than 2.44.1 is acceptable only when regeneration produces either no project
diff or a reviewed, intentional generated-project diff.

`project.yml` is canonical. Whenever a Swift source or asset is added, update
`project.yml` if needed, run `xcodegen generate`, and commit the generated
`NowNest.xcodeproj` change. Do not manually add project references that will be
discarded by regeneration.

The original factory verifier is pinned to `v0.1.0-rc2`. Its release archive is:

```text
https://github.com/edoworks/factory/releases/download/v0.1.0-rc2/factory.tar.gz
SHA-256: 8e1346d5a475cc60ca43a489231db81677dc20b6402ed59ece09fe51f31de856
```

Verify the checksum before extraction. `factory verify` performs an unsigned
archive as its fifth step. Chunks A-C do **not** authorize that archive. Use the
no-archive commands in section 11 during implementation. Run the pinned full
factory verifier only after the owner explicitly authorizes the local unsigned
archive step; this authority still does not authorize upload or publication.

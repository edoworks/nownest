# NowNest Customer Zero PRD

- Status: P0 validation contract
- Source revision audited: build 4 candidate `405b3124bd92d84e69d1bbc947b6a9abf5ed2aef`
- Tracking: `edoworks/factory#54`, implementation `edoworks/factory#55`, TestFlight lifecycle `edoworks/factory#46`
- Evidence cutoff: 2026-09-24
- Accepted-feedback increment: `edoworks/factory#59`

## Product outcome

Protect the founder's current focus while making interrupted intentions easier
to resume later:

```text
CAPTURE -> PARK -> FORGET -> RESURFACE -> REORIENT -> RESUME -> RESOLVE OR RE-PARK
```

The app succeeds when a person can park an interruption, return to current work,
and later encounter a better starting point than the sentence alone.

## Current-state decision

Build `0.1.0 (4)` implements capture, resurface, reorient, Resume, Done, Save
again, and Abandon. It passed 75 tests on each supported simulator family,
static analysis, archive inspection, physical installation and launch on the
owner iPhone and iPad, Apple processing, and internal TestFlight activation.
These facts establish an available validation candidate; they do not establish
Customer Zero usefulness or release readiness.

Fresh build 4 simulator captures pass visual checks for the NowNest identity,
required content, clipping, hierarchy, form-factor adaptation, and calm visual
character. Physical installation and launch are separately verified, but the
simulator visual receipt does not claim physical-device visual or accessibility
qualification.

Build 4 contains no Foundation Models, App Intents, Shortcuts, Siri, Core
Spotlight, notification, background, network, analytics, or account integration.
The current TestFlight app is local SwiftData on iPhone and iPad. Build-bound
feedback now authorizes a later source increment for one optional on-device
starting-action suggestion; it does not retroactively change build 4 behavior.

The active product, repository, and checkout identity is `NowNest`. `FocusGate`
is retained only where historical evidence or an explicit internal-codename
field requires it; it is not an active local checkout or user-facing name.

## Customer Zero interaction

1. Park remains one required text field.
2. Parking automatically records the visible project, outcome, and next action.
3. Parked ideas are visible from the main surface with a count.
4. Opening one shows the exact original thought and the context it interrupted.
5. Resume asks only for a concrete starting action and activates the intention
   without overwriting the underlying NOW.
6. The active intention offers Done, Save again, and Abandon. Internal state
   and historical evidence may continue to use `re-park`.
7. Local content-free events measure the lifecycle. No text or identifier leaves
   the device.

`Resume` is the sole term. `Make NOW` is rejected because the implementation
temporarily overlays the resumed intention while preserving the prior NOW.

## Public-surface wording

Public pages describe the current loop in ordinary language:

1. Keep the current project, outcome, and next action visible.
2. Save an interruption for later without changing NOW.
3. Reopen the saved idea with the context it interrupted.
4. Add one concrete starting action and Resume.
5. Finish with Done, Save again, or Abandon.

Use `Save for later` rather than `Park` in user-facing headings, buttons, feature
names, metadata, and explanations. `PARKED` remains an internal persistence
state. The public headline is `Save it for later. Return to now.`

The website must say that NowNest is still in qualification and is not
currently available for public download. It must not reduce the remaining work
to Apple acceptance: Customer Zero usefulness, seven consecutive days of
voluntary use, exact-candidate validation, build-bound feedback or
`NO_DURABLE_FEEDBACK`, representative external validation, and
willingness-to-pay evidence still precede commercialization. Plain language is
required; repeated legalistic or factory-process wording should not displace
the product explanation.

Public support and legal statements are bounded by implemented behavior and
identity evidence. The current build supports Done, Save again, and Abandon,
not individual hard deletion. Removing the app is the available whole-store
removal path, subject to operating-system offload, backup, and restore behavior;
do not promise irreversible deletion without direct lifecycle evidence.
`NowNest` is provisional and must not be represented as an adopted or
registered trademark until clearance is recorded. Public use of that
provisional identifier requires explicit current owner publication authority;
commercial name adoption requires `CLEARED` identity evidence.

## Feedback traceability

| Evidence | Observed problem | Workflow | Severity | Disposition | Requirement | Acceptance | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Founder direction, 2026-09-23 | TestFlight build is not useful end-to-end | Full lifecycle | P0 | Accept | Complete Park -> Resume -> Resolve | Behavioral simulator and seven-day dogfood gates | Implemented; dogfood validation open |
| Founder direction, 2026-09-23 | Parked items lack a natural return to active work | Resurface/Resume | P0 | Accept | Visible saved entry, context, Resume | Save, relaunch, resume, resolve journey | Implemented in build 4 |
| G8 evidence at commit `8d6f3b5` | “owner confirmed both devices look good” | Visual review | P1 | Preserve, do not generalize | Fresh review for exact candidate | Build-bound physical-device receipt | Stale |
| Build 4 visual receipt, 2026-09-24 | Fresh NowNest identity and layout review | Visual review | P1 | Accept within simulator boundary | Preserve build-bound iPhone/iPad captures | Six visual checks pass on both simulator form factors | Passed; physical visual gate remains open |
| PR rationale only | “bland” concern | Visual identity | P1 | Preserve as unattributed | Complete existing treatment decision | Human comparison issue #32 | Open |
| PR rationale only | “ADHD verbosity concern” | Capture/copy | P1 | Preserve as unattributed | Keep capture terse and Quiet Mode functional | Variant/Quiet Mode matrix | Open |
| Repository audit before authenticated readback | No durable current-build comments or crashes had been recovered | Feedback | P0 gate | Superseded by authenticated readback | Bind each submission to its Apple build relationship | Build/revision-bound receipt | Build 3 correction and build 4 receipt recorded |
| Build 4 feedback, 2026-09-24 | Expected Apple Intelligence to process a saved idea | Starting point | P0 | Accept as product direction, not a build-4 regression | Offer one optional on-device suggestion after save; preserve immediate save and manual fallback | Explicit states, editable suggestion, confirmation before Resume, unavailable/failure tests, iPhone/iPad visual evidence | Issue #59 in progress |

Authenticated readback on 2026-09-24 bound the five earlier submissions to build
3 and one new submission to build 4. The correction is
`evidence/testflight/founder-feedback-build-binding-correction-2026-09-24.json`;
the current-build receipt is
`evidence/testflight/build-4-feedback-2026-09-24.json`. Build-bound feedback is
now present, but its accepted requirement remains open until issue #59 is
implemented and validated.

## Optional on-device suggestion contract

The accepted build-4 direction adds assistance to the saved-idea detail, not to
the interruption path:

1. Saving remains synchronous, local, and immediately returns to NOW.
2. A saved idea remains complete and resumable without Apple Intelligence.
3. The person explicitly requests a suggestion from the saved-idea detail.
4. The app shows saved, preparing, suggestion-ready, unavailable, or failed in
   text and shape; no state relies on color, motion, or Sophie alone.
5. At most one concise starting action is generated from the saved thought and
   interruption context. The original thought is never overwritten.
6. Generated text is labeled `On-device suggestion`, is editable, and does not
   become active until the person chooses Resume.
7. Unsupported devices, disabled Apple Intelligence, model unavailability,
   cancellation, malformed output, and runtime failure preserve the manual field
   and never create a dead end.
8. No network fallback, background processing, telemetry, account, generic chat,
   or automatic task execution is introduced.

## Grounded research disposition

Open-web research remains a separately gated P2 experiment until the P0 lifecycle
proves useful. Issue #59 authorizes only an on-device starting-action suggestion;
it does not authorize research, source retrieval, Private Cloud Compute, or tool
execution. Apple Foundation Models can structure and synthesize supplied evidence;
they do not provide turnkey open-web discovery or citation verification. NowNest
remains responsible for consent, persistence, validation, and side effects.

Any future online research must be explicitly initiated, visibly online, disabled
until chosen, and transmit only the original thought plus the approved research
question. Outputs must retain original thought, question, findings, source-linked
evidence, approaches, tradeoffs, unknowns, and a labeled suggestion. Claims must be
classified as FACT, INFERENCE, SUGGESTION, or UNKNOWN. No source means no factual claim.

## Privacy contract

- `LOCAL`: persistence, context capture, lifecycle transitions, and dogfood events.
- `ONLINE RESEARCH`: future explicit network operation with destination and payload
  disclosure. It is not part of this P0 implementation.
- Never transmit the broader database.
- No content-bearing analytics, account, cloud sync, notification, or background
  capability is introduced by the lifecycle work.

## Seven-day dogfood gate

Commercialization is blocked until the founder voluntarily uses the exact candidate
for seven consecutive days. Record content-free counts for capture attempts,
successful parks, abandoned captures, resurfacing, resumes, re-parks, completions,
and abandonments. Record qualitative observations manually: alternative tool used,
why, missing context, unnecessary/confusing interaction, prevented forgetting, and
reduced restart effort. No historical threshold is invented; the first run establishes
the baseline and requires an explicit founder usefulness decision.

## Release sequence

```text
CUSTOMER ZERO USEFULNESS -> REPEATED DOGFOODING -> EXTERNAL VALIDATION
-> WILLINGNESS-TO-PAY EVIDENCE -> COMMERCIALIZATION
```

Passing tests, an uploaded build, or Apple processing cannot skip a preceding gate.

## Checkout hygiene

The canonical local checkout name is `NowNest`. Before release work, run:

```text
python3 scripts/verify-local-checkout.py --require-clean --require-main-sync
```

The guard fetches live `origin/main`, then rejects legacy checkout names,
sibling legacy paths, dirty state, non-`main` branches, and divergence from the
fetched remote. Historical
evidence remains immutable; local drafts that are not repository evidence must
be archived outside the checkout before synchronization.

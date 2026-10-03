# NowNest Customer Zero PRD

- Status: P0 historical validation contract with an in-progress October 2026 founder-feedback addendum
- Historical source revision audited: build 4 candidate `405b3124bd92d84e69d1bbc947b6a9abf5ed2aef`
- Tracking: `edoworks/factory#54`, implementation `edoworks/factory#55`, TestFlight lifecycle `edoworks/factory#46`
- Evidence cutoff: 2026-09-24
- Accepted-feedback increment: `edoworks/factory#59`
- Accepted-feedback source merged: `edoworks/nownest@66f7b4a`

## Product outcome

Protect the founder's current focus while making interrupted intentions easier
to resume later:

```text
CAPTURE -> PARK -> FORGET -> RESURFACE -> REORIENT -> RESUME -> RESOLVE OR RE-PARK
```

The app succeeds when a person can park an interruption, return to current work,
and later encounter a better starting point than the sentence alone.

## October 2026 founder-feedback addendum (in progress)

This addendum updates the product contract without rewriting the build-4
evidence below. Evidence labels distinguish observation from intent:

| Label | Current evidence and limit |
| --- | --- |
| **Founder report** | Build `0.1.0 (5)` feedback says the update path was confusing; build `0.1.0 (6)` feedback says there is no way to have more than one project and asks for a solo-founder usability critique. The build-6 entry is from an iPhone 16 Pro Max on iOS 27.0.1. These are the founder's reports, not a measured population result. [Authenticated TestFlight screenshot feedback](https://appstoreconnect.apple.com/teams/2807795a-81ff-48cd-850c-533c7a73898d/apps/6814614006/testflight/screenshots). |
| **Source inspection** | Build 6 has one editable `NowContext` and no project roster; editing its name does not retain a separate outcome and next action for the former project. [Models.swift](../NowNest/Models.swift), [ContentView.swift](../NowNest/ContentView.swift). It also queues an on-device review then critiques that draft while the app is active and the model is available; the second pass is a critique, **not independent validation**. [DeferredReview.swift](../NowNest/DeferredReview.swift). |
| **Executed tests** | The build-6 change passed 46 selected iPhone and 33 selected iPad simulator tests. Those deterministic tests cover state and mock model paths, not live Apple Intelligence quality, physical-device layout, or VoiceOver. [Review verification](deferred-review.md); [draft PR #34](https://github.com/edoworks/nownest/pull/34). |
| **Availability** | Apple sent the owner a TestFlight notification for NowNest `0.1.0 (6)` on 2026-10-03. This confirms availability to the notified tester, not an installation or successful real-model run. |
| **Approved direction** | The founder approved **multiple saved projects with one active NOW**, updated PR #34, and an internal TestFlight build after testing. Feature implementation and upload are currently **paused pending this reviewed PRD and open-decision review**. |

Build 6 preserves original saved text and interruption context, exposes an Add
update action and earlier reviews, and keeps Keep, Resume, and confirmed Discard
as user decisions. A model failure or unsupported device retains manual paths.
These are source and simulator-test observations, not claims that a self-critique
correctly judges an idea or that iOS runs the model while the app is suspended.
[Implementation and limitations](deferred-review.md).

### Approved project-switching behavior

1. A visible Add project action creates a named project with its own outcome and
   next action. Empty names and duplicate names are rejected with an explanation;
   stable IDs, not names, associate ideas with projects.
2. A visible project selector identifies the project being viewed and, under the
   proposed interaction, selects one active NOW. Switching saves the previous
   project's current work and restores the selected project's outcome and next
   action after a relaunch. The exact view-versus-activate interaction is open.
3. A saved idea remains attached to its project. Its original text, interruption
   snapshot, updates, review history, user decision, and pending review are not
   rewritten by a project switch. Saved-idea counts and review lists must make
   their project scope clear; changing the active project cannot make ideas look
   deleted. A person's correction to an original thought, if supported later,
   must be explicitly distinguished from appending new context.
4. If a project has a resumed idea, switching leaves that work intact under its
   project. Returning to that project restores it; no work is silently moved,
   completed, or discarded. Automatic review may finish while another project
   is selected, but late output must still be checked against the idea's own
   request and input.
5. Existing build-6 stores migrate in place. The current NOW remains available,
   all existing ideas and model results remain readable, and the migration is
   idempotent. A store-open failure preserves the existing recovery behavior.

### Comparable patterns and rubberduck review

Official product guides show a useful distinction between capturing before
clarifying, viewing one focus, and preserving wider project context. Things
describes an Inbox for unprocessed thoughts, a Someday area for deferred items,
and a Logbook for completed or cancelled items; its docs also distinguish
project context from the Today view. [Things guide](https://culturedcode.com/things/support/articles/4001304/).
Todoist's project documentation makes Add project and switching through a
visible project list explicit. [Todoist project guide](https://www.todoist.com/help/articles/360000031039-%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E3%81%AE%E4%B8%8A%E6%89%8B%E3%81%AA%E4%BD%BF%E3%81%84%E6%96%B9).
OmniFocus documents separate project dispositions, including On Hold,
Completed, and Dropped, and explicit Undo commands. These are examples of
distinct state and recovery affordances, not a request to copy that taxonomy.
[OmniFocus perspectives](https://support.omnigroup.com/documentation/omnifocus/universal/4.9.3/en/perspectives/),
[commands](https://support.omnigroup.com/documentation/omnifocus/universal/4.9.3/en/commands/).
Vendor documentation shows product behavior; it does not establish demand or
benefit for NowNest. No hands-on comparison or outcome study was performed.

Apple advises using a sheet for a brief, focused task with a clear cancellation
path, and avoiding sheets as content navigation. For a short choice list, its
picker guidance suggests a pull-down control; a long list may warrant a list.
These support a focused Add project sheet and a visible project selector on NOW,
instead of using a modal sheet as the primary navigation path.
[Apple Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets),
[Pickers](https://developer.apple.com/design/human-interface-guidelines/pickers/).
Apple's generative-AI guidance supports clear control and recovery around AI
outputs, but it does not make a second pass independent evidence.
[Apple Generative AI](https://developer.apple.com/design/human-interface-guidelines/generative-ai).

The critical solo-founder journey to falsify the design is: capture an idea in
project A; append context; start its review; switch to project B; allow A's
review to finish; return to A; refine its next action; defer it; relaunch;
revisit; then reverse a mistaken action where the app offers reversal. At each
step, the interface must show which project and idea own the data, whether the
update was saved, whether AI is pending/failed/ready, and whether an action is
a user decision. If the founder cannot locate A's idea after the switch, or
believes it was deleted, the design fails even if storage tests pass. A
no-guidance founder walkthrough should record wrong turns and missing context;
no numerical success threshold is approved yet.

### Prototype status and unresolved decisions

The first local prototype (uncommitted and unshipped) has a project record, a
stable optional project ID on ideas, Add/Switch sheets, and per-project active
work. It compiles and three focused store tests pass. This does **not** verify
the feature. The prototype currently assigns every pre-project idea to the
imported active project, even when its recorded origin project differs. That
keeps the text but can mislabel an idea's association. Before shipping, choose
a migration policy that exposes ambiguous historical ideas without inventing
project intent. The recommended default is to retain their original project
snapshot and show them in a clearly labeled imported/uncategorized area until
the founder assigns them; do not silently group them under a possibly unrelated
current project. This is a recommendation, not an approved migration rule.
The prototype's modal Switch project sheet also conflicts with the navigation
guidance above and should be reconsidered before further UI work.

The first prototype also needs explicit duplicate-name feedback in Edit NOW,
clear project scope on the saved-ideas screen, and visual/accessibility review of
the Add/Switch controls. These are source-review findings, not verified fixes.
Other open decisions: whether selecting a project always activates it or can
only view it; what switching does while Capture, Edit, or Review is open;
whether correcting a typo edits the original or appends a labeled correction;
and whether project archive/reopen or Undo are needed in this increment. No
global search, tags, reminders, calendar, or broad task hierarchy is approved.

Acceptance remains open until a frozen build-6 SQLite store migrates without
loss, new and existing projects switch/relaunch with their own work, cancel and
duplicate paths leave state unchanged, ideas and resumed work remain associated,
in-flight review and stale results stay safe, existing capture/update/Keep/
Discard regressions pass, and the critical UI is checked on iPhone and iPad.
These checks attempt to falsify data safety and clarity; passing them does not
prove the app useful to solo founders. Live model quality and physical-device
accessibility remain separate owner checks. This increment does not authorize
cloud inference, imports, orchestration, factory work, public release, or new
testers.

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
| Build 4 feedback, 2026-09-24 | Expected Apple Intelligence to process a saved idea | Starting point | P0 | Accept as product direction, not a build-4 regression | Offer one optional on-device suggestion after save; preserve immediate save and manual fallback | Explicit states, editable suggestion, confirmation before Resume, unavailable/failure tests, iPhone/iPad visual evidence | Merged at `66f7b4a`; replacement-build qualification remains separately gated |

Authenticated readback on 2026-09-24 bound the five earlier submissions to build
3 and one new submission to build 4. The correction is
`evidence/testflight/founder-feedback-build-binding-correction-2026-09-24.json`;
the current-build receipt is
`evidence/testflight/build-4-feedback-2026-09-24.json`. Build-bound feedback is
now present, and its accepted source requirement is implemented and
simulator/local-source validated in
`evidence/ux/issue-59-verification-2026-09-24.json`. A fresh authenticated
readback at closeout found no newer TestFlight submission or crash, no App Store
customer review, and no public App Store version. That result is recorded in
`evidence/testflight/feedback-freshness-2026-09-24.json` and does not qualify the
merged source as a replacement TestFlight build.

### Feedback freshness protocol

Effective after this issue #59 closeout, for any TestFlight, App Store,
release-candidate, or feedback-driven increment:

1. Query authenticated TestFlight screenshot feedback and crash submissions
   before scoping work and again immediately before closeout.
2. Query App Store customer reviews and version state at the same checkpoints
   when an App Store Connect app exists.
3. Bind tester feedback to its Apple build relationship; never transfer feedback
   or an absence claim to a later source revision or build.
4. Exhaust pagination and record endpoint/filter identity, pages traversed,
   total count, latest creation time, a sanitized per-build submission inventory,
   crash count, App Store review count, and version state. Exclude tester and
   reviewer identity, device details, screenshot URLs, and raw free text unless
   a separately protected triage record is required.
5. Treat credential failure, stale key paths, API errors, and unqueried surfaces
   as a blocker. Never translate them into `NO_DURABLE_FEEDBACK` or “no issues.”
6. Re-open scope when a newer material submission exists; otherwise record the
   unchanged watermark before closing the implementation issue.

Issue #59 predates this protocol. Its intake evidence included authenticated,
build-bound TestFlight feedback but did not query App Store customer reviews or
version state; those intake fields are `NOT_RUN`, not inferred. Its closeout
check covers all four required surfaces and establishes the baseline for future
increments.

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

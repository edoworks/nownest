# NowNest Customer Zero PRD

- Status: P0 implementation contract
- Source revision audited: `a055cfc8c1b0f6e42230f5cfd52fe07645d8232f`
- Tracking: `edoworks/factory#54`, implementation `edoworks/factory#55`
- Evidence cutoff: 2026-09-23

## Product outcome

Protect the founder's current focus while making interrupted intentions easier
to resume later:

```text
CAPTURE -> PARK -> FORGET -> RESURFACE -> REORIENT -> RESUME -> RESOLVE OR RE-PARK
```

The app succeeds when a person can park an interruption, return to current work,
and later encounter a better starting point than the sentence alone.

## Current-state decision

The audited build captures and persists a sentence, confirms return to NOW, and
lists parked records behind an overflow menu. It does not resurface, reorient,
resume, complete, or re-park. `ParkedIdea.state` never changes from `PARKED` and
deletion is the only terminal action. This is P0.

No Foundation Models, App Intents, Shortcuts, Siri, Core Spotlight, notification,
background, network, analytics, or account integration exists. The current app
is local SwiftData on iPhone and iPad.

## Customer Zero interaction

1. Park remains one required text field.
2. Parking automatically records the visible project, outcome, and next action.
3. Parked ideas are visible from the main surface with a count.
4. Opening one shows the exact original thought and the context it interrupted.
5. Resume asks only for a concrete starting action and activates the intention
   without overwriting the underlying NOW.
6. The active intention offers Done, Re-park, and Abandon.
7. Local content-free events measure the lifecycle. No text or identifier leaves
   the device.

`Resume` is the sole term. `Make NOW` is rejected because the implementation
temporarily overlays the resumed intention while preserving the prior NOW.

## Feedback traceability

| Evidence | Observed problem | Workflow | Severity | Disposition | Requirement | Acceptance | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Founder direction, 2026-09-23 | TestFlight build is not useful end-to-end | Full lifecycle | P0 | Accept | Complete Park -> Resume -> Resolve | Behavioral simulator and seven-day dogfood gates | In progress |
| Founder direction, 2026-09-23 | Parked items lack a natural return to active work | Resurface/Resume | P0 | Accept | Visible Parked entry, context, Resume | Park, relaunch, resume, resolve journey | In progress |
| G8 evidence at commit `8d6f3b5` | “owner confirmed both devices look good” | Visual review | P1 | Preserve, do not generalize | Fresh review for exact candidate | Build-bound physical-device receipt | Stale |
| PR rationale only | “bland” concern | Visual identity | P1 | Preserve as unattributed | Complete existing treatment decision | Human comparison issue #32 | Open |
| PR rationale only | “ADHD verbosity concern” | Capture/copy | P1 | Preserve as unattributed | Keep capture terse and Quiet Mode functional | Variant/Quiet Mode matrix | Open |
| Repository and available tooling | No durable founder tester comments or crashes recovered | Feedback | P0 gate | Record unavailable | Query/record current-build feedback or `NO_DURABLE_FEEDBACK` | Build/revision-bound receipt | Unavailable |

App Store Connect feedback was not retrieved during the audit because credentialed
Apple operations were outside that read-only authority. It must be retrieved at
the release gate; absence must be recorded as `NO_DURABLE_FEEDBACK`, never inferred.

## Grounded research disposition

Research remains a separately gated P2 experiment until the P0 lifecycle proves
useful. Apple Foundation Models can structure and synthesize supplied evidence;
they do not provide turnkey open-web discovery or citation verification. On-device
sessions are limited to 4,096 tokens. Private Cloud Compute provides a 32K context
on supported OS 27 devices, requires network access and entitlement, and has quotas.
Tool calling executes app-owned code; NowNest remains responsible for retrieval,
source validation, consent, persistence, and side effects.

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

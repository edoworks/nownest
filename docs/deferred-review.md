# Deferred idea review

This local feature adds automatic, on-device reflection for newly saved ideas.
It uses the existing SwiftData store and the iOS 26 Foundation Models API.
There is no cloud inference, account dependency inside the app, background task
registration, notification, or network request.

## Behavior

- Saving a new idea durably queues a review. Existing ideas are not backfilled;
  their detail screen offers a manual review request.
- One app-owned worker processes queued ideas serially while the app is active.
  It reviews the original thought and interrupted project/outcome/action, saves
  that draft, then asks a fresh session of the same model to critique it and
  produce a category, short reason, and uncertainty.
- The critique is a second model pass, not independent validation. The UI labels
  it as fallible AI advice and exposes the first-pass review in a disclosure.
- A saved idea offers **Add update** beside its AI review. The focused sheet has
  Cancel and **Save & review** actions. A saved update is appended with its date;
  the original thought and interrupted context are untouched. The next review
  reads the original and all updates. The previous result remains visibly
  identified while the new review is queued, running, unavailable, or failed;
  older results remain available after the new one completes. The user can still
  keep, resume, or discard explicitly. An update after Keep reopens the decision
  without changing the idea's parked state.
- Optional persisted fields allow lightweight migration from the prior store.
  The worker never writes the original thought, interrupted context, starting
  action, NOW, or idea lifecycle state.
- Keep acknowledges the review while leaving the idea parked. Discard requires
  confirmation and uses the existing ABANDONED state; the original record and
  context are retained locally. Resume remains the existing explicit action.
- Apple Intelligence availability is checked before each pass. Unsupported OS,
  unsupported device, disabled intelligence, and model-not-ready states provide
  a manual path. Generation/refusal/malformed-output errors provide an explicit
  retry. No failure is automatically retried in a loop.
- Inactivation cancels the worker. An interrupted review stays paused until the
  user retries. Relaunch turns any persisted in-flight state into a paused state.
  A completed first pass is reused for retrying a failed/interrupted critique.
- Each pass has a 45-second cancellation timeout. Foundation Models must honor
  task cancellation for the underlying operation to exit; the worker never starts
  overlapping replacement calls. Late output is rejected using a request UUID,
  full input snapshot, idea state, and park count.
- Prompts are limited to 6,000 characters of JSON-encoded input. Longer ideas are
  retained in full and offered manual review; context is never silently truncated.
  Updates are limited to 500 characters each and rejected if their full prompt
  would exceed that bound. Output lengths/categories are validated before any
  summary is presented.

## Apple constraints consulted

[Generating content and performing tasks with Foundation Models](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models)
requires availability checks and a fallback experience. A session handles only
one request at a time. This implementation uses the default on-device model and
separate serial sessions for review and critique.

[Preparing your UI to run in the background](https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-background)
describes suspension and stopping work on deactivation. The feature makes no
promise of processing while iOS suspends the app.

## Interaction references

[Apple's sheet guidance](https://developer.apple.com/design/human-interface-guidelines/sheets)
supports a focused, contextual task with clear Cancel and Save exits. Its
[generative AI guidance](https://developer.apple.com/design/human-interface-guidelines/generative-ai)
supports nearby refinement controls, clear progress, recovery, and user control.
[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons),
[progress indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators),
and [layout guidance](https://developer.apple.com/design/human-interface-guidelines/layout)
inform the short text labels, actual review stages, and adaptable form layout.
The Add update sheet and previous-review label are NowNest design choices guided
by those principles. Apple's 2024 Interaction award for
[Crouton](https://www.apple.com/newsroom/2024/06/apple-announces-winners-of-the-2024-apple-design-awards/)
and 2023 Interaction award for
[Flighty](https://developer.apple.com/design/awards/2023/) illustrate focused
tasks and timely context; no artwork, branding, or interface was copied.

## Verification

The deterministic tests inject model behavior. They verify product behavior,
not the quality of real model output. Physical-device Apple Intelligence quality,
latency, cancellation, and availability require a later device session.

See the local verification checkpoint for commands, result bundle paths, pass
counts, and limitations. A TestFlight upload does not verify the real model's
behavior or a physical device's layout and accessibility.

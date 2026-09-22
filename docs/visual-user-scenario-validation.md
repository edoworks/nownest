# Visual-User Scenario Validation

## Purpose

NowNest uses deterministic scenario validation to check whether its visible
interruption-capture loop remains understandable and recoverable across visual
treatments. The scenario is a behavioral hypothesis, not a diagnosis,
accessibility certification, user study, or commercial forecast.

## Persona hypothesis

The initial hypothesis is a founder managing two work contexts who may benefit
from clear visual hierarchy and a short interruption path. This deliberately
describes observable needs instead of treating ADHD, "visual learner," or any
other label as a uniform user behavior.

## Scenario contract

The test uses the same fixture for `control`, `expressive`, and `sophie`:

1. Identify the visible NOW context and dominant Park action.
2. Capture `Compare standing desks` as an interruption.
3. Confirm that NOW and `Park one real idea` are unchanged after capture.
4. Open Review and confirm the interruption is present with a non-color `PARKED`
   state cue.

The automated pass condition is completion of all four steps with the expected
labels, layout order, preserved next action, and reviewable parked idea.

Each treatment must also render its own confirmation copy: `Parked` for
control, `Tucked away` for expressive, and `Sophie tucked it away` for Sophie.
Confirmation screenshots are retained so variant coverage is visible rather
than inferred from a shared path.

Run destination commands sequentially when they share Xcode's default
DerivedData location. Parallel `xcodebuild` invocations can contend for the
same build database and produce an infrastructure failure unrelated to the
app.

## What automation proves

- The scripted scenario is repeatable on the required simulator form factors.
- The visible hierarchy and interaction path satisfy the assertions in
  `ScenarioValidationTests` for each visual treatment.
- The result bundle contains a structured trace for each treatment.

## What automation does not prove

- That a real person finds NowNest useful, returns to it, or would pay for it.
- That the scenario represents all founders, people with ADHD, or people with
  visual-accessibility needs.
- Physical-device VoiceOver success, broad visual accessibility, or clinical
  effectiveness.

## Calibration and next gate

Compare the automated failure predictions with consented human observations
using the existing Chunk D protocol. Keep raw observations and uncertainty
separate from automated traces. Commercial value requires a separate,
explicitly authorized pricing or willingness-to-pay study; it cannot be
inferred from this offline app's UI tests.

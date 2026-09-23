# Resume sheet dead-end 5-Whys

## Defect

The first end-to-end Resume test activated an idea behind the still-present Review
sheet, leaving two competing `Done` controls and hiding the resumed work.

## Analysis

1. Resume did not visibly return to active work because only the detail sheet dismissed.
2. Review owned a nested sheet and had no explicit success handoff.
3. The transition was initially modeled as a persistence mutation rather than a human journey.
4. Unit tests proved state changes but could not expose navigation ambiguity.
5. The behavioral UI test was the first assertion that the active card must be immediately visible.

## Corrections

- Immediate and root-cause correction: Resume now sends an explicit success event to
  Review, which dismisses the complete review flow and reveals the active intention.
- Recurrence guard: `testParkedIdeaCanResumeAndResolve` waits for the active card's
  uniquely identified completion control immediately after Resume.

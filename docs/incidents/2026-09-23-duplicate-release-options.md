# Duplicate release-option fallback

Date: 2026-09-23
Tracker: edoworks/factory#56

## Defect

Duplicate `-visual-variant` and `-quiet-mode` arguments failed fast in debug
runs but silently retained the first value in release runs. An option adjacent
to a missing value was also consumed as that value, hiding the valid option.
Both behaviors contradicted the argument-pair and release fallback contracts.

## Why chain

1. Release parsing retained the first value because duplicate detection only
   threw when `failFast` was enabled.
2. Non-fail-fast parsing did not retain an invalid-state marker after seeing a
   duplicate.
3. The parser used `variantSeen` and `quietModeSeen` only to support debug
   errors, not release fallback resolution.
4. Adjacent options were consumed as values because value parsing checked only
   array bounds, not whether the next token was another recognized option.
5. Tests covered duplicate debug rejection and unsupported release values, but
   not duplicate release values or adjacent-option missing-value boundaries.
6. Evidence stops there; no cause is asserted for why those release and token-
   boundary cases were omitted from the original matrix.

## Corrections

- Immediate: mark duplicate options invalid in non-fail-fast parsing so variant
  selection falls back to Sophie and Quiet Mode falls back to the stored
  preference.
- Root cause: preserve invalid parse state independently from debug error
  behavior and treat recognized option tokens as missing-value boundaries.
- Recurrence guard: unit tests exercise duplicate release fallback and both
  adjacent-option missing-value paths.

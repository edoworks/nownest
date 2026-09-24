# Suggestion manual-edit race

## Impact

The first issue #59 implementation could replace a starting action that the
person typed while an on-device suggestion was preparing. No shipped build was
affected.

## Root cause

1. A manual edit could be lost because a completed request always assigned its
   output to the starting-action field.
2. The assignment did not check whether the field had changed after the request
   began.
3. The initial tests covered editing after generation, not editing while a
   request was in flight.
4. The interaction contract treated generation and editing separately and did
   not encode their concurrency boundary in a regression test.

Evidence does not support a deeper cause.

## Correction and guard

The request records the field value it started from and applies output only if
the field still has that value. Otherwise the manual edit wins and the detail
returns to its saved state. A deterministic delayed-response UI test edits the
field while generation is in flight and fails if generated text replaces it.

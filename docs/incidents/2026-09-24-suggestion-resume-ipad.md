# Suggestion detail Resume discovery on iPad

## Impact

The first issue #59 implementation placed suggestion controls above the existing
Starting point field. On iPad, the separate action section fell outside the
Form's materialized viewport, so the full UI suite could not discover Resume.
No shipped build was affected.

## Root cause

1. Resume was not discoverable because its separate Form section was below the
   visible detail content on iPad.
2. The section moved below the viewport because new state and suggestion rows
   increased the preceding content height.
3. The layout assumed Form would expose offscreen controls before scrolling;
   iPad UI automation showed that assumption was false.
4. Focused verification ran on iPhone first, where the section remained
   discoverable, so the form-factor-specific regression appeared only in the
   full iPad matrix.

Evidence does not support a deeper cause.

## Correction and guard

Resume now sits in the Starting point section directly after the editable field
and its guidance. UI journeys scroll the Form until the stable Resume identifier
is materialized when a taller state requires it. The existing and new Resume
journeys run in the full iPhone and iPad suites, mechanically guarding control
discovery and manual fallback.

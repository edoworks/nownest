# G2 Dark Appearance Contrast 5-Whys

Status: RESOLVED locally; retain as recurrence analysis.

1. Why is NOW content unreadable in the dark-appearance frame? Semantic primary text resolves to a light color while the card remains white.
2. Why do those colors conflict? The card background is hard-coded to white opacity and the view does not constrain its color scheme.
3. Why was that combination accepted? Verification covered build and behavior, but rendered review was captured only after the simulator was already in dark appearance and no contrast gate rejected it.
4. Why was there no contrast gate? The release evidence lane did not require appearance variants as a separate machine-readable visual check.
5. Why is that a recurrence risk? Future UI changes can pass tests while producing unreadable dark-mode surfaces.

Immediate correction: capture and retain a valid light-mode baseline, classify the dark-mode frame as a release blocker, and stop before signing.

Root-cause correction: make appearance-aware visual evidence and contrast validation an explicit pre-release requirement before G5.

Implemented correction: replace the fixed white card surface with `Color(.secondarySystemBackground)` while retaining semantic text colors.

Recurrence guard: add a dark-appearance simulator screenshot/contrast check to the FocusGate release evidence lane before the next archive candidate. The corrected iPhone and iPad frames are recorded in `g2-simulator-2026-09-20.json`.

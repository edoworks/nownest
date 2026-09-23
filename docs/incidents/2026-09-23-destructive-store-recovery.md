# Non-destructive store recovery 5-Whys

## Defect

Any production `ModelContainer` open failure deleted the local store, WAL, and SHM.

## Analysis

1. User data could disappear because the catch-all recovery path called `removeStore`.
2. The path treated every open failure as confirmed unrecoverable corruption.
3. Recovery was optimized for relaunch success, not preservation of the only local copy.
4. The regression test asserted deletion rather than data safety.
5. Release criteria tested recovery availability but did not require quarantine or user notice.

## Corrections

- Immediate: move the failed store files into a local recovery directory before
  creating a fresh store, and notify the user.
- Root cause: release criteria now require non-destructive recovery and prior-store
  migration evidence.
- Recurrence guard: the unit test fails unless the original bytes survive in the
  recovery directory.

No claim is made that the preserved SQLite files are automatically repairable.

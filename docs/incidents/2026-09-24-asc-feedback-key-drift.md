# App Store Connect feedback key-path drift

## Impact

The first closeout feedback query stopped before contacting App Store Connect
because the shell environment still pointed to a removed pre-rotation key file.
No feedback was omitted from the proposed closeout because the query was rerun
with the current approved key and succeeded while the issue remained open.

## Root cause

1. The feedback query failed because its configured private-key path did not
   exist.
2. The path referred to the pre-rotation key rather than the current approved
   key.
3. The long-lived shell environment had not been reconciled after the key
   rotation.
4. The query correctly trusted its explicit environment instead of silently
   selecting a different credential.

Evidence does not support a deeper cause.

## Corrections and recurrence guard

The closeout query was rerun with the current approved key and returned a fresh,
sanitized TestFlight watermark. App Store customer reviews and version state
were queried separately with the same GET-only authentication boundary.

The existing `--check-only` command remains fail closed when its configured key
is absent; this prevented a stale credential from being mistaken for an empty
feedback result. The PRDs now require authenticated intake and closeout checks
and explicitly treat credential, API, or coverage failure as a blocker rather
than `NO_DURABLE_FEEDBACK`.

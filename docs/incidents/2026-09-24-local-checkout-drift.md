# Local checkout drift and legacy path

## Impact

The active local checkout remained at the legacy `/Users/hello/FocusGate` path,
its `main` branch was behind the merged TestFlight work, and a redundant local
plist edit blocked fast-forward synchronization. Two unique untracked metadata
drafts also prevented a simple clean-state assertion.

## Five Whys

1. Local `main` could not fast-forward because `NowNest/Info.plist` was marked
   modified.
2. The local edit added the same export-compliance declaration later merged by
   the isolated TestFlight branch, but the canonical checkout was not reconciled
   after that merge.
3. Release work used an isolated worktree to protect pre-existing local state,
   while the older checkout remained on its prior revision.
4. Cleanup was deferred because the two untracked draft reports had not been
   classified as repository evidence, superseded material, or disposable data.
5. The repository had no mechanical post-merge check for canonical checkout
   name, cleanliness, branch, and remote equality.

## Corrections

- The drafts were hash-verified and archived outside the repository under a
  NowNest-named path.
- The plist blob was verified byte-for-byte against `origin/main`, the checkout
  was fast-forwarded, and stale remote-tracking refs were pruned.
- The active checkout was renamed to `/Users/hello/NowNest`; the separate clean
  deprecated checkout was removed after proving it had no unique branch or tag.
- `scripts/verify-local-checkout.py` is the recurrence guard for checkout name,
  sibling legacy paths, cleanliness, branch, and fetched remote equality.

Historical product references remain preserved. This correction removes active
legacy paths; it does not rewrite evidence or repository history.

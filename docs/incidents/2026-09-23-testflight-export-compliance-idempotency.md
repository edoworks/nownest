# TestFlight export-compliance activation failure

## Impact

Build 4 processed successfully, but the first activation attempt stopped before
confirming internal TestFlight state and group membership.

## Five Whys

1. Activation failed because App Store Connect returned HTTP 409 for the export-
   compliance PATCH.
2. App Store Connect rejected the PATCH because `usesNonExemptEncryption` was
   already `false`.
3. The uploaded app already declared `ITSAppUsesNonExemptEncryption=false` in
   its effective plist, so processing populated the build attribute.
4. The activator always issued a PATCH and assumed setting the same value was
   idempotent.
5. Mock coverage had only modeled an unset attribute and did not include the
   already-declared archive path.

## Corrections

- Immediate: verify the build's current attribute and skip the PATCH when it is
  already `false`.
- Root cause: retain fail-closed response checks while treating the verified
  target state as success rather than requiring a mutation.
- Recurrence guard: `test_already_declared_export_compliance_skips_patch`
  exercises the processed-build state produced by the effective plist.

No unsupported cause is asserted beyond the observed API response and checked
archive metadata.

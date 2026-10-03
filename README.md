# NowNest

NowNest is an offline iPhone and iPad reference app for protecting the
current NOW context when a new idea appears.

## Scope

The v0 loop is deliberately small:

```text
see NOW -> capture idea -> park locally -> confirm -> resume NOW
```

NOW and parked ideas use local SwiftData storage. The app has no network,
accounts, analytics, notifications, background work, or cloud backup.
Newly saved ideas receive an advisory on-device review and critique while the
app is active, when Apple Intelligence is available. Original content is retained
and only the user can keep, resume, or discard. A saved idea can receive a dated
update that prompts a fresh review while retaining the earlier result. See
[Deferred idea review](docs/deferred-review.md) for availability and recovery behavior.

## Factory Provenance

This project was initialized from the downloaded `edoworks/factory`
`v0.1.0-rc2` source archive.

- Archive SHA-256: `8e1346d5a475cc60ca43a489231db81677dc20b6402ed59ece09fe51f31de856`
- Factory init receipt: `.factory-verify.json`
- Factory verification receipt: `.factory-verify-result.json`

The factory verifier's fifth step creates an unsigned archive. Run it only at a
release gate with explicit archive authorization. During ordinary implementation
use the PRD's no-archive build, test, and analysis commands.

## Product Planning

- [Calm Expressive UX PRD](docs/calm-expressive-ux-prd.md) defines the bounded
  visual-language prototypes, Sophie guardrails, accessibility contract,
  verification matrix, human decision gate, and implementation chunks.

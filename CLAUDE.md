# TravelVault

Encrypted, offline-first travel document vault. Built with Flutter. Developed
with the Braveheart AiDevTeam workflow.

## Product Principles

TravelVault's entire value proposition is **privacy and trust**. Every
engineering decision serves this:

- **No cloud.** Vault features make zero network calls. No account, no sync, no
  telemetry, no analytics SDKs.
- **Encrypted at rest.** All persisted data lives in a SQLCipher-encrypted
  SQLite database.
- **Keys stay on device.** The encryption key lives only in the iOS Keychain /
  Android Keystore. Never hardcode it, never log it, never persist it elsewhere.
- **Biometric gate.** The app locks behind Face ID / Touch ID / Android
  biometrics on cold start and on resume from background.

If a change would weaken any of these, stop and raise it — it is not a normal
trade-off.

## Workflow Philosophy

Every feature follows a disciplined pipeline. No skipping straight to code.

```
Discovery → Exploration → Clarifying Questions → Architecture → Implementation → Review
```

## Agent Roles

| Role             | Command            | Description                                  |
|------------------|--------------------|----------------------------------------------|
| Feature Dev      | `/feature-dev`     | Full pipeline from discovery to implementation |
| Architect        | `/architect`       | System design, API contracts, data modeling  |
| Code Review      | `/code-review`     | Multi-pass review with actionable feedback    |
| Security Auditor | `/security-review` | OWASP top 10, dependency audit, secrets scan  |
| Batch Worker     | `/batch`           | Spin up parallel agents for independent tasks |
| Loop Runner      | `/loop-until-done` | Iterate until success criteria are met        |
| Second Opinion   | `/second-opinion`  | Cross-validate decisions and implementations  |
| Designer         | `/design-system`   | UI/UX patterns, component architecture        |
| Test Writer      | `/test-suite`      | Generate comprehensive test coverage          |
| Refactor         | `/refactor`        | Improve code quality without changing behavior |

## Code Standards (Flutter / Dart)

- Write tests for new functionality. Logic must be testable without a device —
  use `sqflite_common_ffi` for DB-backed tests.
- Run `flutter analyze` and `flutter test` before pushing — both must be clean.
- No secrets or credentials in code — keys live in the platform secure store.
- Prefer composition over inheritance; keep widgets small and focused.
- Use meaningful names — code should read like prose.
- Handle errors at system boundaries (DB, biometrics, file I/O); trust internal
  code.
- No premature abstractions — three similar lines beat one clever helper.
- Default to no comments; comment only the non-obvious "why".

## Security Rules

- Never commit `.env`, keystores, credentials, API keys, or tokens.
- All SQL must be parameterized — never string-build queries.
- No `eval`-style dynamic execution.
- No network calls in vault features. If a feature needs the network, it must
  be explicitly called out and reviewed.
- Never log document contents, MRZ data, or the encryption key.
- Validate all user input at system boundaries.

## Git Conventions

- Branch naming: `feature/`, `fix/`, `refactor/`, `test/`
- Commit messages: imperative mood, explain the "why"
- One logical change per commit
- Always run `flutter analyze` and `flutter test` before pushing

## Review Checklist

Before any PR is created, verify:
- [ ] `flutter analyze` is clean
- [ ] `flutter test` passes
- [ ] No security vulnerabilities introduced
- [ ] No hardcoded secrets or keys
- [ ] No network calls added to vault features
- [ ] Error handling at boundaries
- [ ] Code is readable without excessive comments
- [ ] No unnecessary dependencies added

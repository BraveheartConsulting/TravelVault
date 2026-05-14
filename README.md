# TravelVault

**Your travel documents and itineraries, secured on-device. No cloud, no accounts, no breach risk.**

TravelVault is an encrypted, offline-first travel vault for iOS and Android. It
combines a secure document vault (passports, visas, tickets, booking numbers)
with trip management — in a single app that never sends your data anywhere.

## Status

Early development. This repository currently contains the **foundation
increment**: project scaffold, encrypted persistence layer, biometric lock
gate, and core data models. Feature UI (document viewer, trip CRUD, OCR/MRZ
scanning, expiry notifications, IAP) comes in later increments.

## Architecture

| Concern            | Choice                                                        |
|--------------------|---------------------------------------------------------------|
| Framework          | Flutter (single codebase, iOS first, Android to follow)       |
| Persistence        | SQLCipher-encrypted SQLite via `sqflite_sqlcipher`            |
| Encryption key     | 256-bit random key in iOS Keychain / Android Keystore         |
| Auth gate          | Biometric (Face ID / Touch ID / Android biometrics)           |
| State / routing    | Riverpod + go_router                                          |

### Security model

- The database file is encrypted at rest with SQLCipher (AES-256).
- The encryption key is generated on first launch and stored **only** in the
  platform secure enclave (Keychain / Keystore). It is never hardcoded, never
  logged, and never written to the database file.
- The app makes **zero network calls** for vault features. There is no account,
  no telemetry, no cloud sync.
- All queries are parameterized — no string-built SQL.

## Project layout

```
lib/
  app/         App shell, routing, theme
  core/
    crypto/    Encryption key management
    db/        Encrypted database + schema
    security/  Biometric lock gate
  data/
    models/    Profile, Document, Trip, TripStop, TripDocument
    repositories/  Parameterized data access
  features/    Lock / Home / Settings screens (placeholders for now)
test/          Unit tests for crypto, db, and repositories
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
```

Tests run on the desktop host via `sqflite_common_ffi` — no device required.

## Built with the Braveheart AiDevTeam

This project uses the Braveheart DevTeam workflow (`.claude/` commands +
`CLAUDE.md`): a disciplined Discovery → Exploration → Clarifying Questions →
Architecture → Implementation → Review pipeline.

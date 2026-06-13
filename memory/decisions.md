# AOSA — Architecture Decision Records

## ADR-001: Flutter over .NET MAUI

**Date**: 2026-06-13  
**Status**: Accepted  

**Context**: Need cross-platform support for Android, iOS, iPadOS, Linux, and macOS. Both Flutter and .NET MAUI offer cross-platform development.

**Options Considered**:
1. **Flutter** — Dart, Impeller renderer, 5-platform support
2. **.NET MAUI** — C#, native wrappers, tight Azure integration

**Decision**: Flutter

**Rationale**:
- True single codebase for all 5 target platforms (MAUI desktop is immature)
- Impeller renderer provides 120fps guaranteed frame budget
- Hot reload is 3-5x faster than MAUI
- Larger package ecosystem for crypto/security (pub.dev)
- Better community tooling for TOTP generation

**Consequences**:
- Need separate Dart/Flutter expertise (not .NET)
- Binary size ~15-25MB larger than native

---

## ADR-002: Zero-Trust Client-Side Encryption

**Date**: 2026-06-13  
**Status**: Accepted  

**Context**: Self-hosted backend stores OTP data. Traditional approach stores plaintext + server-side encryption.

**Options Considered**:
1. **Client-side encryption** (zero-trust): Encrypt before sending to server
2. **Server-side encryption**: Server holds encryption keys
3. **HTTPS-only**: Rely solely on transport security

**Decision**: Client-side encryption (zero-trust)

**Rationale**:
- Server compromise does not leak OTP secrets
- User controls their own key (derived from PIN)
- Server never sees plaintext data
- Architectural simplicity: server is an opaque blob store

**Consequences**:
- Key management is client's responsibility
- PIN change requires re-encryption of all data
- Slightly larger payload per record (encryption overhead)

---

## ADR-003: Riverpod over Bloc

**Date**: 2026-06-13  
**Status**: Accepted  

**Context**: State management choice for Flutter app.

**Options Considered**:
1. **Riverpod 2.x** — compile-safe, no BuildContext required
2. **Bloc** — widely used, good for complex state machines
3. **Provider** — predecessor to Riverpod, less type-safe

**Decision**: Riverpod 2.x

**Rationale**:
- Compile-time safety (no runtime ProviderNotFoundException)
- No BuildContext dependency (testable, usable in services)
- Better support for async streams (OTP auto-refresh)
- Simpler code generation vs Bloc boilerplate
- Native support for `StreamProvider` (perfect for real-time OTP updates)

---

## ADR-004: SQLite (Drift) for Local Storage

**Date**: 2026-06-13  
**Status**: Accepted  

**Context**: Local data persistence for OTP accounts, settings, sync queue.

**Options Considered**:
1. **Drift** (SQLite ORM) — type-safe, reactive queries, migration support
2. **Hive** — NoSQL key-value, limited query capability
3. **Isar** — NoSQL, performant, but discontinued maintenance

**Decision**: Drift (SQLite ORM)

**Rationale**:
- Supports complex queries (search, filter, sort)
- Built-in migration system for schema evolution
- Reactive `Stream` queries integrate directly with Riverpod
- Mature, well-maintained, large community
- Encryption via `sqlcipher` or application-layer encryption

---

## ADR-005: Soft-Delete with Tombstones

**Date**: 2026-06-13  
**Status**: Accepted  

**Context**: Delete propagation across devices in sync scenario.

**Options Considered**:
1. **Hard delete** — immediate removal, no propagation
2. **Soft delete with tombstones** — mark as deleted, sync tombstone
3. **CRDT-based deletion** — complex, over-engineered for v1

**Decision**: Soft delete with tombstones

**Rationale**:
- Deletes propagate to all devices via normal sync
- Tombstones are garbage-collected after 90 days
- Simple to implement and reason about
- User can see "recently deleted" for undo

**Consequences**:
- Additional storage for tombstones
- Need garbage collection logic on server

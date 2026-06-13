# AOSA — Change Log & Decisions

## 2026-06-13 — Project Initialization

### v0.0.0 — Initial Commit
- Established project directory structure
- Wrote 6 specification documents covering all aspects of the app
- Initialized `memory/` system for development tracking
- Created `bugfixes/log.md` for issue tracking

### Architectural Decisions
1. **Flutter** chosen over .NET MAUI for cross-platform (see `memory/decisions.md` ADR-001)
2. **Zero-trust encryption model** — all data encrypted client-side (see ADR-002)
3. **Riverpod** for state management (see ADR-003)
4. **Drift** for local SQLite persistence (see ADR-004)
5. **Soft-delete with tombstones** for sync (see ADR-005)
6. **Last-Write-Win** conflict resolution with version counters
7. **AES-256-GCM** for data encryption, **Argon2id** for PIN hashing

### Technology Versions Targeted
- Flutter 3.x (latest stable)
- Dart 3.x
- ASP.NET Core 9+ (Minimal APIs)
- PostgreSQL 16+ (server) / SQLite (local)
- Riverpod 2.x
- Drift 2.x

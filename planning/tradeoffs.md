# AOSA — Technology Tradeoffs & Decisions

## Framework: Flutter vs MAUI

| Criterion | Flutter | MAUI | Winner |
|---|---|---|---|
| Android support | ✅ Mature | ✅ Mature | Flutter |
| iOS/iPadOS | ✅ Mature | ⚠️ Many Xamarin migration bugs | Flutter |
| Linux desktop | ✅ Stable via GTK | ❌ No official support | Flutter |
| macOS | ✅ Stable | ⚠️ Unstable, missing controls | Flutter |
| Hot reload | ✅ <1s | ⚠️ 3-5s | Flutter |
| Binary size | ~25MB baseline | ~15MB baseline | MAUI |
| Dart ecosystem | Smaller but growing | Massive .NET ecosystem | MAUI |
| Security/crypto | ✅ pointycastle, cryptography | ✅ System.Security.Cryptography | Tie |

**Verdict**: Flutter wins on platform coverage and developer experience. The binary size difference is negligible for a modern authenticator app.

## State Management: Riverpod vs Bloc

| Criterion | Riverpod | Bloc |
|---|---|---|
| Compile safety | ✅ Never runtime errors | ⚠️ ProviderNotFoundException possible |
| Boilerplate | Low | High (Event, State, Bloc classes) |
| Stream support | ✅ Native (StreamProvider) | ⚠️ Requires extra wiring |
| Testing | ✅ Simple override | ✅ Well-documented |
| Community | Smaller but growing | Large, well-established |

**Verdict**: Riverpod's compile safety and lower boilerplate make it the better choice for a project where productivity matters.

## Local DB: Drift vs Hive vs Isar

| Criterion | Drift | Hive | Isar |
|---|---|---|---|
| Query support | ✅ SQL (complex) | ❌ Key-value only | ⚠️ Limited |
| Migrations | ✅ Built-in | ❌ Manual | ⚠️ Manual |
| Reactive streams | ✅ Native | ❌ | ✅ |
| Maintenance | ✅ Active | ✅ Active | ❌ Discontinued |
| Encryption | ✅ Via sqlcipher | ❌ | ❌ |

**Verdict**: Drift provides the query power of SQLite with a type-safe Dart API. Hive's simplicity is not worth the query limitations for this app.

## Encryption: AES-256-GCM vs ChaCha20-Poly1305

| Criterion | AES-256-GCM | ChaCha20-Poly1305 |
|---|---|---|
| Hardware support | ✅ AES-NI on all platforms | ❌ Software-only on most |
| Performance (mobile) | ✅ Very fast | ⚠️ Slower without HW |
| Key size | 256-bit | 256-bit |
| Nonce size | 12 bytes | 12 bytes |
| Standard | ✅ NIST/FIPS | ✅ RFC 8439 |

**Verdict**: AES-256-GCM benefits from hardware acceleration on all target platforms (AES-NI on ARM/Intel), making it faster and more energy-efficient. Both are equivalently secure.

## KDF: Argon2id vs bcrypt vs PBKDF2

| Criterion | Argon2id | bcrypt | PBKDF2 |
|---|---|---|---|
| Memory-hard | ✅ Yes | ❌ No (4KB fixed) | ❌ No |
| Side-channel resistant | ✅ Yes | ⚠️ Vulnerable | ⚠️ Vulnerable |
| GPU/ASIC resistant | ✅ Excellent | ⚠️ Moderate | ❌ Weak |
| Standard | ✅ RFC 9106 | ❌ No formal standard | ✅ NIST |

**Verdict**: Argon2id is the 2015 Password Hashing Competition winner and is the most resistant to GPU/ASIC attacks. It is the clear choice for PIN-based key derivation.

## Sync Protocol: LWW vs CRDT vs OT

| Criterion | LWW | CRDT | OT |
|---|---|---|---|
| Complexity | Low | Medium | High |
| No conflict needed | ✅ Always resolves | ✅ Always resolves | ⚠️ Needs server |
| Deletion handling | ⚠️ Tombstones needed | ✅ Built-in | ❌ Complex |
| UX with conflicts | ⚠️ Can lose data | ✅ Automatic merge | ✅ Automatic merge |

**Verdict**: LWW with version counters is the pragmatic choice for v1. CRDTs add significant complexity with marginal benefit for opaque encrypted blobs where the server cannot interpret content.

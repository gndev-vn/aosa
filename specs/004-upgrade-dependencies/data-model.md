# Data Model Specification: Dependency Modernization & Package Upgrade

**Feature**: Dependency Modernization & Package Upgrade
**Directory**: `specs/004-upgrade-dependencies`
**Status**: Completed (Phase 1)

---

## Entities

### 1. `DependencyRecord` (Value Object)

Represents an individual dependency in the application package ecosystem.

| Field | Type | Required | Constraints / Validation | Description |
|---|---|:---:|---|---|
| `name` | `String` | Yes | Non-empty lowercase string | Unique package name on pub.dev |
| `type` | `DependencyType` | Yes | `direct`, `dev`, `transitive` | Dependency category within the manifest |
| `currentVersion` | `String` | Yes | Valid SemVer format | Currently locked version in `pubspec.lock` |
| `targetVersion` | `String` | Yes | Valid SemVer format | Upgraded version to be installed |
| `bumpType` | `VersionBumpType` | Yes | `major`, `minor`, `patch` | Classification of version delta |
| `constraint` | `String` | Yes | Caret or range syntax (e.g. `^11.1.1`) | Version constraint defined in `pubspec.yaml` |
| `isBreaking` | `bool` | Yes | Boolean flag | True if upgrading involves breaking API changes |

#### Lifecycle & State Transitions
```text
[Current Version: Outdated] ──> [Resolve Candidate] ──> [SAT Solver Evaluation]
                                                               │
                                                               ▼
[Lock Update: Installed] <── [Verify Compile & Tests] <── [Apply Constraint]
```

---

### 2. `CompatibilityAuditEntry` (Domain Entity)

Represents the validation and audit record for an upgraded package.

| Field | Type | Required | Constraints / Validation | Description |
|---|---|:---:|---|---|
| `packageName` | `String` | Yes | Matching `DependencyRecord.name` | Package name audited |
| `oldVersion` | `String` | Yes | SemVer string | Baseline version before upgrade |
| `newVersion` | `String` | Yes | SemVer string | Resulting version after upgrade |
| `breakingChanges` | `List<String>` | Yes | List of breaking notes (empty if none) | Documented breaking API changes |
| `remediatedDeprecations` | `List<String>` | Yes | List of fixed deprecations | Warnings and deprecations addressed |
| `verificationStatus` | `Status` | Yes | `passed`, `failed`, `pinned` | Build and regression test status |
| `testedPlatforms` | `List<String>` | Yes | Subsets of `windows`, `macos`, `linux`, `android`, `ios` | Platforms verified |

---

### 3. `PackageManifest` (Configuration Model)

Represents the project package manifest specification (`pubspec.yaml`).

| Field | Type | Required | Description |
|---|---|:---:|---|
| `appName` | `String` | Yes | Application identifier (`aosa`) |
| `sdkConstraint` | `String` | Yes | Dart SDK boundary (`^3.5.0`) |
| `flutterConstraint` | `String` | Yes | Flutter framework boundary (`^3.27.0`) |
| `dependencies` | `Map<String, String>` | Yes | Map of package names to version constraints |
| `devDependencies` | `Map<String, String>` | Yes | Map of dev tool dependencies |

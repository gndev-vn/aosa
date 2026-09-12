# Feature Specification: Dependency Modernization & Package Upgrade

**Feature Branch**: `004-upgrade-dependencies`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "looks like there are many outdated packages. let"

## Clarifications

### Session 2026-09-12

- Q: Upgrade strategy scope — Should we perform a safe non-breaking upgrade or a full major upgrade including breaking versions? → A: Option B (Full Upgrade — Major + Minor) — Bump `pubspec.yaml` constraints to latest resolvable versions (including major breaking releases such as Flutter Riverpod 3, Flutter Secure Storage 11, Google Fonts 8, Shimmer 4, and UUID 4) and refactor any resulting API breaking changes immediately.
- Q: Target platform verification gate — Which platforms should serve as the validation gate? → A: Option B (All Supported Platforms — Desktop + Mobile) — Require build and smoke verification across both desktop environments (Windows, macOS, Linux) and mobile targets (Android, iOS).
- Q: Deprecation remediation policy — How should the team handle new deprecation notices? → A: Option A (Remediate Straightforward Deprecations) — Fix clean, direct deprecation replacements in touched files; document any complex or architectural deprecations for follow-up.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Safe Dependency Modernization Without Functional Regression (Priority: P1)

As an AOSA maintainer and end user, I want the application's third-party dependencies updated to their latest major, minor, and patch releases, so that the application benefits from modern language features, security patches, platform bug fixes, and performance improvements while preserving 100% of existing authenticator features (token generation, vault management, biometric lock, QR scanning, cloud sync, and desktop integration).

**Why this priority**: Outdated libraries leave the application vulnerable to unpatched platform issues, security advisories, and future build tool incompatibilities. Ensuring existing features continue operating flawlessly through major and minor version bumps is the primary goal of this modernization.

**Independent Test**: Can be independently verified by updating package versions in manifests, resolving dependencies, refactoring any breaking API changes, running the full test suite, launching the application, and verifying that all core OTP operations (generating codes, importing tokens, unlocking vault, scanning codes, copying to clipboard) function identically to the baseline.

**Acceptance Scenarios**:

1. **Given** an installed application running on the updated package set, **When** the user launches the app and views the vault, **Then** all previously stored accounts appear with exact matching codes and continuous countdown timer operations without crash or visual distortion.
2. **Given** the upgraded package set, **When** executing standard security interactions (e.g., biometric authentication, secure storage read/write, PIN setup), **Then** all cryptographic and vault storage operations complete without data corruption or permission failures.
3. **Given** the application running on desktop platforms (Windows, macOS, Linux), **When** window resizing, hotkey triggers, system tray operations, and notifications are activated, **Then** desktop integration capabilities remain fully operational.
4. **Given** the application running on mobile platforms (Android, iOS), **When** camera scanning, biometric unlock, and theme adaptations occur, **Then** all mobile-specific features operate without crash or permission degradation.

---

### User Story 2 - Automated Verification & Clean Build Quality (Priority: P2)

As a developer and automated build system, I want all package upgrades and required API refactorings to compile cleanly without unresolved dependency conflicts, build breaks, or regression test failures across all supported target platforms, so that ongoing development and CI/CD pipelines run smoothly.

**Why this priority**: A dependency upgrade that breaks builds, causes linter errors, or produces unresolvable constraint conflicts halts development velocity and introduces hidden stability risks.

**Independent Test**: Can be independently verified by running dependency resolution commands, automated static analysis/linter checks, and the full automated test suite to confirm zero compile errors, passing test assertions, and zero unresolved version conflicts across targeted platforms.

**Acceptance Scenarios**:

1. **Given** updated dependency declarations, **When** dependency resolution is executed, **Then** all direct and transitive dependencies resolve cleanly without version conflict errors or broken dependency trees.
2. **Given** resolved dependencies, **When** static analysis and linter checks run, **Then** the project compiles with zero fatal errors and conforms to project lint standards.
3. **Given** the project test suite, **When** automated unit, widget, and platform interface tests run, **Then** all test suites pass with 100% success rate matching or exceeding baseline coverage.

---

### User Story 3 - Transparent Dependency Audit & Supply Chain Traceability (Priority: P3)

As a project maintainer, I want a clear summary document detailing each package upgraded (its prior version, new version, changelog highlights, breaking changes refactored, and deprecations addressed), so that the team maintains complete traceability over external software supply chain updates.

**Why this priority**: Visibility into dependency changes simplifies future troubleshooting if a third-party regression is introduced upstream and documents the rationale for major version transitions.

**Independent Test**: Can be verified by inspecting the generated upgrade report, verifying that every modified package has its previous version, target version, and upgrade category (major, minor, or patch) accurately cataloged along with any migration notes.

**Acceptance Scenarios**:

1. **Given** a completed upgrade pass, **When** reviewing the change summary, **Then** each modified dependency is documented with its version transition (e.g., from vX.Y.Z to vA.B.C) and associated upgrade classification.
2. **Given** any dependency with API changes or deprecation notices, **When** reviewing the audit, **Then** the audit clearly notes any refactoring performed or future migration actions needed.

---

### Edge Cases

- **Transitive Dependency Clashes**: What happens when two packages require conflicting versions of a shared transitive dependency? The dependency resolution must identify the highest compatible converging version or reject incompatible candidates to preserve build stability.
- **Platform-Specific Native Plugin Breakages**: What happens if a platform plugin (e.g., local authentication, secure storage, or window management) behaves differently on a specific OS after upgrade? Build verification and smoke testing across all targeted operating systems (Windows, macOS, Linux, Android, iOS) ensure issues are discovered immediately.
- **Breaking API Changes in Major Releases**: What happens if an essential package has a major version bump that alters public APIs (such as Riverpod or Secure Storage)? Breaking changes must be identified and code refactored across all call sites to restore seamless compilation and test parity.
- **Data Store Schema or Serialization Incompatibilities**: What happens if an updated storage or serialization dependency changes format expectations? Storage migrations or backward-compatibility adapters must ensure existing stored vaults remain uncorrupted and readable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST resolve and upgrade outdated direct and transitive dependencies to stable, active versions while maintaining a mutually compatible dependency graph.
- **FR-002**: System MUST preserve all existing application capabilities (TOTP/HOTP calculation, vault persistence, biometric authentication, QR code scanning, system tray, window management, and notifications) with zero behavioral regressions.
- **FR-003**: System MUST execute a full dependency upgrade covering both major and minor package versions (bumping constraints in `pubspec.yaml` to latest resolvable releases) and immediately refactor any resulting breaking API changes.
- **FR-004**: System MUST validate build and runtime integrity across all supported target platforms, including desktop targets (Windows, macOS, Linux) and mobile targets (Android, iOS).
- **FR-005**: System MUST remediate straightforward deprecation notices introduced by newer library versions in touched code files, while documenting any complex deprecations requiring separate architectural migrations.
- **FR-006**: System MUST ensure that automated unit and integration tests execute successfully with 100% pass rate following dependency updates.
- **FR-007**: System MUST produce an audit report documenting all updated libraries, old and new version numbers, and rationale for any pinned or constrained packages.

### Key Entities *(include if feature involves data)*

- **Dependency Record**: Represents an individual package in the manifest, including package name, dependency type (direct, dev, or transitive), current installed version, resolvable version, and latest available upstream version.
- **Compatibility Audit Entry**: Represents the verification record for an upgraded package or group of packages, capturing resolution status, breaking change evaluation, deprecation notes, and verification test outcomes across all supported platforms.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of targeted outdated packages are upgraded to their approved target versions with zero unresolved version constraints.
- **SC-002**: Zero compilation failures and 100% pass rate across the existing automated test suite after dependency updates and API refactoring.
- **SC-003**: Zero functional regressions observed during smoke testing across core user journeys (vault loading, OTP calculation, biometric lock, and account creation) on desktop and mobile platforms.
- **SC-004**: Total count of reported outdated dependencies is reduced by at least 80% based on the full major and minor upgrade scope.

## Assumptions

- The project relies on standard pub / Flutter package management workflows using `pubspec.yaml` and `pubspec.lock`.
- Major version bumps with breaking changes will be refactored directly in the codebase during implementation.
- Existing automated unit and widget tests provide an accurate baseline for regression detection.
- Core encryption algorithms and RFC test vectors remain the absolute standard for verifying token calculation integrity.

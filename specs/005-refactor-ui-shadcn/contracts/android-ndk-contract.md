# Interface Contract: Android NDK Build Configuration

**Contract Scope**: Build toolchain configuration in `app/android/app/build.gradle.kts`.

---

## 1. Specification

- **Target File**: `app/android/app/build.gradle.kts`
- **NDK Version Specification**:
  ```kotlin
  android {
      ndkVersion = "30.0.16248370"
  }
  ```
- **Invariants**:
  - Direct reference to installed side-by-side NDK directory: `C:\Users\khanh\AppData\Local\Android\Sdk\ndk\30.0.16248370`.
  - Eliminates reliance on `flutter.ndkVersion` requesting uninstalled 28.x versions.
  - Prevents Gradle from calling deprecated `sdkmanager` CLI tool on build.
  - Ensures clean `flutter build apk --config-only` and `flutter run` execution.

# AOSA — Bugfix Log

## Format
```
## YYYY-MM-DD — Bug #[ID]

**Description**: What went wrong
**Root Cause**: Why it happened
**Fix**: What was changed
**Prevention**: How to avoid in future
**Files Changed**: path/to/file.dart:line
```

---

## 2026-07-19 — Bug #001: "No host specified in URI repos/" on fresh launch

**Description**: When launching the app for the first time (or without a previously configured server), the home screen attempted to load repos from the cloud API, resulting in `DioException: Invalid argument(s): No host specified in URI repos/`. The Default repo appeared to fail loading.

**Root Cause**: `home_screen.dart:_loadActiveRepoId()` called `loadRepos(apiClient)` without checking if `apiClient.dio.options.baseUrl` was configured. The `ApiClient` is initialized with an empty `baseUrl`, and `updateBaseUrl()` is only called when the user connects to a server. On fresh install (no `server_url` in storage), `configureSync()` is never called, so `baseUrl` remained empty. Dio then tried to resolve the relative path `repos/` against an empty base URL, producing the hostless URI error.

**Fix**: 
1. `home_screen.dart:60` — Added `services.apiClient.hasBaseUrl` guard before calling `loadRepos`
2. `repo_provider.dart:49` — Added defense-in-depth early return in `loadRepos()` when `!api.hasBaseUrl`

**Prevention**: Always guard API calls that depend on a configured base URL. The `ApiClient.hasBaseUrl` getter exists for this purpose — use it before any network call that requires server connectivity.

**Files Changed**:
- `app/lib/presentation/screens/home_screen.dart:60` — Added `hasBaseUrl` guard
- `app/lib/presentation/providers/repo_provider.dart:49` — Added defense-in-depth guard in `loadRepos()`

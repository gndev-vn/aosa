# AOSA — API Specification v1.0

Base URL: `https://{host}:{port}/api/v1`

## Authentication

### POST /auth/register
Register a device with the server.

**Request:**
```json
{
  "device_id": "uuid-string",
  "device_name": "My Pixel 9",
  "pin_public_salt": "base64-32-bytes",
  "public_key": "base64-ed25519-public"
}
```

**Response (201):**
```json
{
  "device_token": "jwt-string",
  "refresh_token": "jwt-string",
  "server_version": 0
}
```

### POST /auth/refresh
Refresh an expired JWT.

**Request:**
```json
{
  "refresh_token": "jwt-string"
}
```

**Response (200):**
```json
{
  "device_token": "new-jwt-string",
  "refresh_token": "new-jwt-string"
}
```

---

## OTP Records

All payloads are **opaque encrypted blobs**. The server never reads the plaintext.

### GET /otp
List all non-deleted OTP records for the authenticated device.

**Response (200):**
```json
{
  "items": [
    {
      "id": "uuid",
      "encrypted_blob": "base64-string",
      "version": 3,
      "created_at": "2026-06-13T00:00:00Z",
      "updated_at": "2026-06-13T00:00:00Z"
    }
  ],
  "server_version": 42
}
```

### POST /otp
Create a new OTP record.

**Request:**
```json
{
  "id": "uuid",
  "encrypted_blob": "base64-string",
  "client_timestamp": "2026-06-13T00:00:00Z"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "version": 1,
  "created_at": "2026-06-13T00:00:01Z"
}
```

### PUT /otp/{id}
Update an existing OTP record. Uses optimistic concurrency via version.

**Request:**
```json
{
  "encrypted_blob": "base64-string",
  "expected_version": 3,
  "client_timestamp": "2026-06-13T00:00:00Z"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "version": 4,
  "updated_at": "2026-06-13T00:00:01Z"
}
```

**Response (409 — Conflict):**
```json
{
  "error": "conflict",
  "current_version": 5,
  "message": "Record has been updated by another device. Fetch latest and re-apply."
}
```

### DELETE /otp/{id}
Soft-delete an OTP record (creates a tombstone).

**Request:**
```json
{
  "expected_version": 3
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "deleted_at": "2026-06-13T00:00:01Z",
  "version": 4
}
```

---

## Sync

### GET /sync/status
Get the current server version for quick sync check.

**Response (200):**
```json
{
  "server_version": 42,
  "device_version": 35
}
```

### GET /sync/pull?since_version={v}
Pull all changes since a given version (inclusive). Includes tombstones.

**Response (200):**
```json
{
  "items": [
    {
      "id": "uuid",
      "encrypted_blob": "base64-string",
      "version": 7,
      "created_at": "...",
      "updated_at": "...",
      "deleted_at": null
    }
  ],
  "server_version": 42
}
```

### POST /sync/push
Push local changes to the server.

**Request:**
```json
{
  "changes": [
    {
      "id": "uuid",
      "encrypted_blob": "base64-string",
      "expected_version": 3,
      "client_timestamp": "..."
    }
  ]
}
```

**Response (200):**
```json
{
  "accepted": [
    { "id": "uuid", "new_version": 5 }
  ],
  "conflicts": [
    {
      "id": "uuid",
      "server_version": 6,
      "message": "stale version"
    }
  ]
}
```

---

## Health

### GET /health

**Response (200):**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime_seconds": 3600
}
```

---

## Error Format

All errors follow this envelope:

```json
{
  "error": "error_code",
  "message": "Human-readable description",
  "details": {} // optional
}
```

### HTTP Status Codes Used
| Code | Meaning |
|---|---|
| 200 | Success |
| 201 | Created |
| 400 | Bad request (validation error) |
| 401 | Unauthenticated (missing/invalid JWT) |
| 403 | Forbidden (device mismatch) |
| 404 | Not found |
| 409 | Conflict (version mismatch) |
| 429 | Too many requests (rate limit) |
| 500 | Internal server error |

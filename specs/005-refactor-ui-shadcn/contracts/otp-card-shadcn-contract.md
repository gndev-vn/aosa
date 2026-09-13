# Interface Contract: Shadcn OTP Account Card

**Contract Scope**: Visual layout, state transitions, and interaction behavior of the redesigned `OtpCard`.

---

## 1. Card Anatomy & Layout

```text
┌─────────────────────────────────────────────────────────────┐
│ [Avatar]  Issuer Name                           [Progress]  │
│           account.label@email.com                   [18s]   │
│                                                             │
│       4 9 1   8 2 3          [📋 1-Tap Copy Trigger]        │
└─────────────────────────────────────────────────────────────┘
```

- **Surface**: `ShadCard` with 12dp rounded corners, 1px border (`#27272a`), and clean surface background (`#18181b`).
- **Avatar**: 40x40dp monogram container with gradient or brand accent tint.
- **Header**: High-contrast issuer name in `Inter w600` (16sp) with muted account email (13sp).
- **Countdown Indicator**: Circular progress ring or subtle animated linear bar showing remaining fraction.
- **Urgent Expiration Warning**: When `timeLeft <= 5`, indicator transitions from primary accent to warm warning color (`#f59e0b` or `#ef4444`).

---

## 2. Interaction Contract: 1-Tap Copy

- Tapping anywhere on the code or copy button triggers:
  1. Instant clipboard write.
  2. Temporary morphing of copy icon to an animated checkmark icon.
  3. Visual confirmation badge (`"Copied!"`) with haptic pulse (via `HapticFeedback.lightImpact()`).
  4. Auto-reversion back to normal state after `1500ms`.
- Tapping long-press or settings triggers the action bottom sheet.

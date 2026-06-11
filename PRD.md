# QuickHacks — Product Requirements Document

**Version:** 1.0 · **Date:** 2026-06-11 · **Platform:** macOS 14.0+ · **Status:** Approved for implementation

## 1. Vision

QuickHacks is a lightweight macOS menu bar app that collects fast, everyday system
tweaks in one place: decluttering the menu bar itself, guarding against unwanted
Bluetooth audio routing, keeping the Mac awake, and one-click system toggles.
It must be general-purpose (not tailored to one user) and structured so it could
ship to the Mac App Store.

## 2. Target Users

- Power users with crowded menu bars who want Bartender-style collapsing for free
- People whose Bluetooth headphones auto-connect/steal audio when they don't want it
- Anyone who wants common Terminal tweaks (hidden files, desktop icons) as toggles

## 3. Features

### F1 — Menu Bar Declutter (P0)

- A separator icon and a chevron toggle appear in the menu bar.
- Clicking the chevron (or auto after N seconds) collapses every third-party icon
  positioned to the LEFT of the separator (standard ⌘-drag arrangement).
- Technique: second `NSStatusItem` whose length is expanded to push items off-screen
  (same approach as Hidden Bar / Dozer — App Store proven).
- Settings: auto-collapse after delay (off/15/30/60 s), show/hide separator.

### F2 — Bluetooth Guard (P0)

- List all paired Bluetooth devices with connection state and device class icon.
- Per-device **Block**: when a blocked device connects, QuickHacks immediately
  disconnects it (IOBluetooth connect notifications → `closeConnection`).
- Per-device quick Connect / Disconnect actions.
- Blocklist persists across launches.

### F3 — Keep Awake (P0)

- Prevent display/system sleep via `IOPMAssertion`.
- Durations: 15 min, 1 h, 4 h, indefinitely; live countdown; one-click off.

### F4 — Quick Toggles (P0)

| Toggle                 | Mechanism                                                            |
| ---------------------- | -------------------------------------------------------------------- |
| Dark Mode              | AppleScript via System Events (Automation permission)                |
| Hide desktop icons     | `defaults write com.apple.finder CreateDesktop` + Finder restart     |
| Show hidden files      | `defaults write com.apple.finder AppleShowAllFiles` + Finder restart |
| Empty Trash            | Finder AppleScript                                                   |
| Lock Screen            | `CGSession -suspend`                                                 |
| Screenshot → Clipboard | `screencapture -ic` (interactive region)                             |

### F5 — Settings (P1)

- Launch at login (`SMAppService.mainApp`).
- Feature visibility (hide unused sections).
- About panel with version.

## 4. Non-Functional Requirements

- SwiftUI UI, AppKit only where required (NSStatusItem, NSPopover).
- Swift 6 strict concurrency; services are `@MainActor` observable classes.
- Architecture: Views → Feature stores → Services. No business logic in views.
- Persistence: `UserDefaults` with Codable models, versioned keys.
- No private APIs in core paths; shell-based toggles isolated in one service so a
  sandboxed App Store build can disable/replace them per-feature.
- Functions ≤ 40 lines, files ≤ 300 lines, named exports, Result-style errors.
- Unit tests for stores/models (XCTest); app builds via `swift build` + bundle script.

## 5. Acceptance Criteria

1. `swift build` succeeds with zero warnings-as-errors issues; `swift test` green.
2. `Scripts/build-app.sh` produces a signed (ad-hoc) `QuickHacks.app` that launches
   as a menu-bar-only app (`LSUIElement`).
3. Collapsing hides icons left of the separator; expanding restores them.
4. Blocking a paired device disconnects it within ~1 s of connecting.
5. Keep Awake prevents sleep for the chosen duration and auto-expires.
6. All quick toggles execute and report errors in the UI (no silent failures).
7. Launch at login toggle reflects real `SMAppService` status.

## 6. Out of Scope (v1)

- Global hotkeys, per-app audio routing, Focus/DND control (no public API),
  iCloud sync of settings, localization beyond English UI strings.

## 7. Sprint Plan

| Sprint               | Scope                                                                   | Deliverable              |
| -------------------- | ----------------------------------------------------------------------- | ------------------------ |
| S1 — Foundation      | Package, app bundle script, status item, popover shell, design tokens   | App launches in menu bar |
| S2 — Core Services   | KeepAwake, QuickToggles (shell runner), Settings store, launch at login | Toggles functional       |
| S3 — Bluetooth Guard | Device listing, connect notifications, blocklist enforcement            | F2 complete              |
| S4 — Declutter       | Separator/chevron items, collapse logic, auto-collapse                  | F1 complete              |
| S5 — Polish & QA     | UI polish per DESIGN.md, tests, error states, build verification        | Shippable .app           |

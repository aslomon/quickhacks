# QuickHacks

A lightweight macOS menu bar app that collects fast, everyday system tweaks in
one place. SwiftUI, macOS 14+, no dependencies.

## Features

- **Menu Bar Declutter** — collapse third-party menu bar icons behind a
  separator (⌘-drag icons to the left of the `⟋` separator to hide them).
  Optional auto-hide after 15/30/60 s.
- **Menu bar apps in the panel** — every third-party menu bar app is listed
  inside the QuickHacks panel with its app icon; clicking it opens that item
  directly via Accessibility (AXPress on the app's extras menu bar — no Screen
  Recording permission needed). The menu bar itself stays clean.
- **Settings tab** — launch at login, GitHub-based update check, and
  "Move to Applications" installer.
- **Bluetooth Guard** — see all paired devices, connect/disconnect with one
  click, and _block_ devices: a blocked device is disconnected automatically
  the moment it connects (e.g. headphones that keep stealing your audio).
- **Keep Awake** — prevent display sleep for 15 min / 1 h / 4 h / indefinitely,
  with a live countdown.
- **Quick Toggles** — only things Control Center does NOT cover: mute
  microphone, show hidden files, hide desktop icons, auto-hide Dock, eject all
  disks, empty Trash.
- **Launch at login** via `SMAppService`.

## Build & Run

Requires Xcode 16+ command line tools.

```bash
./Scripts/build-app.sh        # builds build/QuickHacks.app (release, ad-hoc signed)
open build/QuickHacks.app
```

Development:

```bash
swift build                   # debug build
swift test                    # unit tests
```

## Permissions

On first use macOS will ask for:

- **Bluetooth** — to list paired devices and enforce the blocklist.
- **Automation (Finder)** — for Empty Trash and Eject all disks.
- **Accessibility** — to open other apps' menu bar items from the panel.

Launch-at-login only works from the `.app` bundle, not from `swift run`.

## Architecture

```
Sources/QuickHacks/
  App/        entry point, NSStatusItem + custom NSPanel (not NSPopover —
              NSPopover positions unreliably on status items)
  Design/     design tokens (see DESIGN.md)
  Services/   one @MainActor service per feature, UserDefaults persistence
  Views/      SwiftUI panel UI, no business logic
```

Hard-won platform notes:

- Other apps' status window **bounds are masked** by macOS without Screen
  Recording permission — coordinate-based clicking is impossible. Items are
  activated via `AXPress` on the app's `AXExtrasMenuBar` instead.
- The declutter separator must never collapse on launch and never when our
  own items sit left of it (guarded in `MenuBarDeclutterService`), otherwise
  the app hides its own controls.

Shell-based toggles are isolated in `ShellRunner` so a sandboxed App Store
build can replace them per feature. See `PRD.md` for full requirements and
`DESIGN.md` for the design system.

## App Store Notes

The declutter technique (expanding `NSStatusItem`) is the same approach used
by Hidden Bar, which ships on the Mac App Store. For an MAS build: enable the
App Sandbox, keep Bluetooth + Apple Events entitlements, and disable the
`CGSession`/`defaults`-based toggles or replace them with sandbox-safe
equivalents (`QuickToggleAction` is the single switch point).

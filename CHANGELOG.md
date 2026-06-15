# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Live accessibility permission detection: Panel now polls for permission changes every 1.5 seconds so it updates immediately when the user grants access in System Settings
- Popover-style anchor arrow on the panel pointing at the status item icon
- Helpful explanatory text under "Grant access" button explaining that ad-hoc signed rebuilds require re-granting accessibility permission
- Custom vector app icon master asset, generated macOS iconset, and bundled `.icns`
- Launch verification script covering strict Swift build, tests, bundle metadata, icon, and code signature
- MIT license, contribution guide, security policy, issue templates, and pull request template
- GitHub Actions for CI, GitHub Pages, and tagged release ZIP publishing
- Static GitHub Pages site for non-technical users
- Release ZIP packaging script with first-run install notes

### Changed

- Panel positioning now factors in arrow height for proper alignment with menu bar
- Arrow position dynamically tracks the status item button, clamped to panel bounds to prevent overflow at screen edges
- Release builds now regenerate and embed the app icon automatically
- Shell-based system commands now time out instead of hanging indefinitely
- README rewritten for public GitHub launch and normal Mac users

### Fixed

- Declutter feature not working in UI: Setting had been toggled off in user preferences (not a code issue, but now verified working)
- Swift strict-concurrency verification for Bluetooth and Accessibility bridge code

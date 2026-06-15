# Contributing to QuickHacks

Thanks for helping improve QuickHacks.

## Before You Start

- Keep user-facing text clear and friendly.
- Keep code, comments, and docs in English.
- Keep the app native, small, and dependency-light.
- Read `DESIGN.md` before changing UI or visual assets.

## Local Checks

Run these before opening a pull request:

```bash
./Scripts/verify-launch.sh
```

For smaller code-only changes, at minimum run:

```bash
swift build
swift test
```

## Pull Requests

- Explain what changed and why.
- Include screenshots for UI changes.
- Add or update tests for behavior changes.
- Do not include personal settings, build products, or generated local files.

## Public Distribution

QuickHacks release ZIPs are currently intended for GitHub Releases. Developer
ID signing and notarization are still tracked as release follow-up work.

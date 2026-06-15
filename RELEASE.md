# QuickHacks Release Checklist

Use this checklist before publishing a build.

## Public Repository

Create the public GitHub repository once:

```bash
gh repo create aslomon/quickhacks --public --source=. --remote=origin
git push -u origin main
```

Then enable GitHub Pages in the repository settings:

- Source: GitHub Actions
- URL: `https://aslomon.github.io/quickhacks/`

## Local Release Build

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`.
2. Update `CHANGELOG.md`.
3. Run:

   ```bash
   ./Scripts/verify-launch.sh
   ```

4. Launch `build/QuickHacks.app` and manually check:
   - Status bar icon appears with the custom app icon in Finder/Dock/Launchpad.
   - Popover opens from the menu bar item.
   - Accessibility permission prompt appears when needed.
   - Bluetooth devices list and block/unblock works with a real paired device.
   - Keep Awake starts, stops, and expires.
   - Quick Toggles surface inline errors instead of hanging.
   - Launch at login only enabled from the `.app` bundle.

## GitHub Release ZIP

Package a release locally:

```bash
./Scripts/package-release.sh
```

The package is written to `dist/QuickHacks-v<version>.zip`.

Publish through GitHub Actions:

```bash
git tag v<version>
git push origin v<version>
```

The release workflow builds the app, packages the ZIP, and creates a GitHub
Release with the ZIP attached.

## Direct Distribution

The current build script creates an ad-hoc signed local build. Before public
download distribution, replace ad-hoc signing with Developer ID signing and
notarize the app.

Required follow-up:

- Add Developer ID identity selection to `Scripts/build-app.sh`.
- Add notarization and stapling script.
- Verify Gatekeeper on a clean macOS user account.

## Mac App Store

The current architecture isolates shell-based toggles in `QuickToggleService`
and `ShellRunner`, but an App Store build still needs an explicit sandbox review.

Required follow-up:

- Add an Xcode project or export pipeline that supports App Store signing.
- Add App Sandbox entitlements.
- Keep Bluetooth and Apple Events usage descriptions.
- Disable or replace non-sandbox-safe `defaults`, `killall`, and Finder
  automation actions for the store build.
- Prepare App Store Connect metadata, screenshots, privacy answers, and support URL.

## Icon Assets

The app icon is source-controlled as `Resources/AppIcon.svg` and generated with:

```bash
./Scripts/generate-icons.sh
```

The generated `Resources/QuickHacks.icns` is copied into the app bundle by
`Scripts/build-app.sh`.

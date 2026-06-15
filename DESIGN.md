# QuickHacks — Design System

Single source of truth for all visual decisions. Read before any UI work.

## Mood & Direction

**Functional Warm Minimal** — a dense-but-calm utility popover. Native macOS feel
(vibrancy, SF Symbols) with one warm accent. No gradients, no purple-blue, no emoji
icons, no decorative chrome. The popover should read like a crafted system panel,
not a web dashboard.

## Color Palette

Semantic colors adapt to light/dark via system materials; the accent is fixed.

| Token           | Value                                     | Usage                                    |
| --------------- | ----------------------------------------- | ---------------------------------------- |
| `accent`        | `#E85D3A` (warm coral)                    | Active states, toggles ON, block badge   |
| `accentSoft`    | accent @ 12% opacity                      | Active row backgrounds, chips            |
| `textPrimary`   | `Color.primary`                           | Titles, values                           |
| `textSecondary` | `Color.secondary`                         | Captions, metadata                       |
| `dangerText`    | `#C7392B`                                 | Destructive actions (Empty Trash, Block) |
| `surface`       | `.ultraThinMaterial` / popover background | Section cards                            |
| `divider`       | `Color.primary @ 8%`                      | Hairline separators                      |

Status colors: connected = system green; blocked = accent; idle = secondary.

## Typography

System fonts only (native feel is the brand).

| Scale   | Spec                                                         | Usage                       |
| ------- | ------------------------------------------------------------ | --------------------------- |
| Display | SF Pro Rounded, 15 pt, semibold                              | App title in popover header |
| Heading | SF Pro, 11 pt, semibold, uppercase, +0.6 tracking, secondary | Section headers             |
| Body    | SF Pro, 13 pt, regular                                       | Row labels, device names    |
| Caption | SF Pro, 11 pt, regular, secondary                            | States, countdowns, hints   |
| Mono    | SF Mono, 11 pt                                               | Countdown timer digits      |

## Spacing — 8pt Grid

`4 / 8 / 12 / 16 / 24` only. Popover content inset: 12. Row height: ≥ 28.
Popover width: fixed 320 pt.

## Shape & Depth

- Corner radius: 8 (rows/cards), 6 (chips/buttons), continuous style.
- No shadows inside the popover (the popover itself provides depth).
- Hairline dividers between sections, none between rows.

## Iconography

SF Symbols exclusively, `.medium` weight, 13–15 pt, monochrome secondary by
default; accent-colored when state is active. Menu bar icon: `bolt.square.fill`
(template). Chevron item: `chevron.left` / `chevron.right`.

## App Icon

The app icon is a deterministic vector asset at `Resources/AppIcon.svg`.
It uses the warm coral accent on a quiet macOS-style tile with one centered
custom lightning bolt. The icon must stay text-free, emoji-free, low-detail,
and recognizable at 16 pt.

Generated launch assets:

- `Resources/QuickHacks.icns` — bundled app icon.
- `.build/generated-icons/QuickHacks.iconset` — regenerated source iconset.

Regenerate with `./Scripts/generate-icons.sh`; `./Scripts/build-app.sh` does
this automatically before assembling the app bundle.

## Motion

- State changes: `.spring(duration: 0.25, bounce: 0.15)`.
- Keep Awake countdown: numeric `contentTransition`.
- Collapse/expand of menu bar: instant (system constraint), button icon animates.

## Signature Detail (the 120% element)

The Keep Awake row morphs: idle it is a quiet row; active it becomes an
accent-tinted capsule with a live monospaced countdown and a subtle pulsing
`bolt.fill` symbol effect. This is the one expressive moment in the UI.

## Component Patterns

- **Section**: uppercase heading + grouped rows on `surface`, radius 8.
- **ToggleRow**: SF symbol (18 pt frame) + label + trailing `Toggle` (.switch, accent tint).
- **ActionRow**: symbol + label, whole row clickable, hover highlight `accentSoft`.
- **DeviceRow**: device-class symbol + name + state caption; trailing block
  button (`nosign` symbol, accent when blocked) + connect/disconnect on hover.
- **Error surfaces**: inline caption in `dangerText` under the affected row,
  auto-dismiss after 5 s. Never alerts for routine failures.

## Tone

UI copy: short, sentence case, no exclamation marks, English. Errors say what
happened + what to do ("Finder needs Automation permission. Open Settings…").

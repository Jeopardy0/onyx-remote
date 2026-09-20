# Onyx Remote

An iPad programming assistant for the Obsidian Onyx lighting console: patch
view, fixture programming, a virtual NX K keypad, and playback control. Fills
the gap left by the official iPhone-only "Onyx Remote," which doesn't report
cuelist status.

Read `docs/PLAN.md` for milestones/risks/open questions and
`docs/ONYX_INTEGRATION.md` for exactly what Onyx's OSC/Telnet/CITP interfaces
document (and what they don't — nothing here is guessed).

## Project layout

```
Packages/
  PatchKit/    fixture/universe model, conflict detection, auto-addressing
               — pure Swift, no Apple frameworks, builds/tests anywhere
  ConsoleKit/  ConsoleAdapter protocol, action vocabulary, MockConsoleAdapter
               — pure Swift, same as above
  OnyxKit/     OSC codec (pure Swift) + the real Onyx transport/adapter
               (Network.framework, Apple-only, wrapped in #if canImport(Network))
App/
  OnyxRemote/       the SwiftUI app target
  OnyxRemoteUITests/  screenshot walk of every screen, run in CI
project.yml    XcodeGen spec — there is no committed .xcodeproj; it's
               generated fresh by `xcodegen generate` (also done in CI)
```

## Running against the mock console

The app talks to a `ConsoleAdapter` protocol (see `Packages/ConsoleKit`), and
defaults to `MockConsoleAdapter` — a fully in-memory Onyx stand-in seeded with
sample fixtures/playbacks that match `docs/design/`. Every screen works
against it with no console, network, or Onyx software required:

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
2. From the repo root: `xcodegen generate`
3. Open `OnyxRemote.xcodeproj` in Xcode 15+ and run the `OnyxRemote` scheme
   on an iPad simulator (iOS 17+).

To point the app at a real console instead, swap `MockConsoleAdapter` for
`OnyxKit`'s `OnyxConsoleAdapter` where `AppModel` constructs its
`ConsoleSession` (`App/OnyxRemote/AppModel/AppModel.swift`) — this isn't wired
up to any UI yet (no connection-settings screen exists), so it currently
means editing that line directly. A proper "enter console IP" flow is part of
M1 finishing up.

## Development happens without local Xcode

This repo is developed from a phone/remote environment with no local Xcode
install. `PatchKit` and `ConsoleKit` are pure Swift and were built/tested
directly with the open-source Swift toolchain on Linux during development;
everything Apple-only (the SwiftUI app, `OnyxKit`'s transport) is only ever
verified by CI (`.github/workflows/ci.yml`), which builds the app, runs every
package's unit tests, and uploads a screenshot of each screen as a workflow
artifact — check the Actions tab (or the GitHub mobile app) after each push.

## Fonts

IBM Plex Sans and IBM Plex Mono, bundled under the SIL Open Font License
(`App/OnyxRemote/Resources/Fonts/OFL.txt`) — no Obsidian/NX K branding is
reproduced anywhere in the app.

## Status

M0 (this scaffold) is complete: all seven screens, both packages' full test
suites, and the CI/screenshot pipeline. See `docs/PLAN.md` for what's next
(M1 is Onyx OSC — real console verification required) and the open
questions blocking it.

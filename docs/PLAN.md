# Plan — Onyx iPad Remote

Companion to `docs/ONYX_INTEGRATION.md` (protocol facts) and the design
screenshots in `docs/design/`. This is the milestone/risk breakdown; see the
original task prompt for full screen-by-screen behavior specs.

## Milestones

### M0 — Scaffold
Swift packages (`PatchKit`, `ConsoleKit`, `OnyxKit`) + app target, design
tokens, tab navigation, all seven screens built statically against sample
data via `MockConsoleAdapter`. GitHub Actions macOS workflow builds + runs
tests + captures simulator screenshots as CI artifacts on every push.
**Does not depend on any open question below** — it's pure UI against a mock,
so it can start immediately without blocking on Onyx answers.
**Acceptance:** CI green; screenshots visually match `docs/design/`.

### M1 — Onyx OSC
`OnyxKit` transport (`NWConnection` UDP), connection chip with
reconnect/backoff, virtual keypad sending real `/Mx/button/52xx` etc. presses,
playback GO/Release (target TBD — OSC Playback Pages vs. main playback block
vs. Telnet, see Open Questions #1), whatever feedback is documented wired up
(command line mirror, HIGHLIGHT-based Locate). Unit tests for the OSC codec
against the addresses in `ONYX_INTEGRATION.md` §1. **This is the milestone
blocked on your answers below.**
**Acceptance:** works against our own OSC mock server; works against the real
console when you test it; codec unit tests pass.

### M2 — Patch
Real patch model in `PatchKit`, Map/List/Walk views, Add Fixtures sheet,
conflict detection, auto-addressing, undo, JSON persistence.
**Acceptance:** unit tests pass; can build and re-address a 200-fixture patch
fully offline.

### M3 — Program and Position
Fixture selection, value entry (composed from keypad presses per §1.6/1.8 of
the integration doc — no absolute-value OSC message exists), palettes via
command line, Update/Record flows.
**Acceptance:** a programmer can select, set, and record a preset entirely
from the iPad against a real console.

### M4 — CITP / patch push
Feature-flagged. Two candidate paths per the integration doc: (a) CITP scan
trigger + import, protocol details unverified; (b) generate a native Onyx
patch XML file for manual import via "Read ONYX Patch" — needs one real
exported sample file from you to reverse-engineer the schema.
**Acceptance:** documented findings on what Onyx actually accepts; a working
push of a simple patch via whichever path proves feasible.

### M5 — Polish
Confirmations, error states, VoiceOver labels, performance pass on an older
iPad.

## Risks

- **OSC playback control may require a paid Onyx license** — stated directly
  in the mapping PDF for both the main playback block and Playback Pages. If
  your console/license doesn't have it, GO/Release on the Cues screen has to
  fall back to Telnet/UDP (`GQL`/`RQL`/`PQL`/`SQL`/`GTQ`, fully documented,
  no license language attached) instead of OSC. Need to know which channel
  you can actually use before M1's Cues wiring is real rather than mocked.
- **No documented way to read live cue-list contents or state** beyond a
  coarse per-playback name/level/LED and the command-line status text. The
  Cues screen's per-cue Now/Next list with timing (as mocked) likely can't be
  fully console-driven — v1 may need to treat cue *names/times* as
  locally-authored/imported data, with only GO/Release/level actually round-
  tripping to the console. This is a real UX compromise to flag to you, not
  a v1-vs-v2 detail to quietly decide.
- **PFA/PFB/PFC/PFD semantics on the main playback block are undocumented.**
  Wiring the "obvious" 20-playback OSC block for Go/Release risks pressing
  the wrong button on a real rig. Must be verified hands-on before it ships,
  even behind a "beta" label.
- **CITP protocol depth is unverified.** Obsidian's own docs only describe
  it at a UI-workflow level (auto-detect, scan, import). Full M4 CITP work
  may need real back-and-forth against a live console rather than protocol
  docs alone — budget for that.
- **Development is phone-only, no local Xcode.** All verification of build
  correctness routes through CI. Any SwiftUI layout regression only surfaces
  from the CI screenshot artifacts — slower feedback loop than normal iOS
  dev. Keep commits small for exactly this reason.
- **Onyx patch XML schema is unpublished.** M4's "native import" path is
  blocked on getting one real sample file from your console.
- **Apple's multicast entitlement approval timeline is unknown** and gates
  CITP discovery (M4). Should be requested early (now) rather than when M4
  starts, per the original prompt.

## Open questions (blocking M1 — please answer before we wire real OSC)

1. **Playback control path:** does your Onyx license/install include OSC
   playback control (main block and/or Playback Pages), or should GO/Release
   target Telnet/UDP (`GQL`/`RQL`/etc.) instead? If you don't know, tell us
   and we'll build the Cues screen against whichever channel you can test
   first, behind the `playbackControl` capability flag so the other stays
   dark until verified.
2. **OSC port:** what Incoming Port do you actually configure on the
   console's OSC Device entry? (No default is published — see integration
   doc §1.1.) We'll make it a required manual field either way, but a real
   number lets us set a sane default in the connection screen.
3. **Console access for testing:** will you be testing M1 against a real
   Onyx console/software during development, or should we assume mock-only
   until later? Changes how much we invest in the mock server's fidelity
   up front.
4. **Onyx software version:** which Onyx version are you running? Telnet
   requires 4.10+; some OSC mapping details may differ by version, and the
   patch XML schema (M4) is version-sensitive per the Patch Import docs
   ("shows previous to software version 4.6 may not import").
5. **Apple Developer account for the multicast entitlement request** (needed
   for CITP discovery in M4): do you have one we should use to file the
   request now, in parallel with M0–M3, given approval time is unknown?
6. **Fixture library data for `PatchKit`:** the app needs a fixture profile
   library (name, modes, channel counts) for "Add fixtures". Do you have an
   export from Onyx's own library we should seed from, or should M2 ship
   with a small hand-authored set (LED Wash / Spot Mover / LED Bar, matching
   the design mockups) plus the custom-profile entry path, and grow the
   library later?

M0 does not depend on any of the above and can start now.

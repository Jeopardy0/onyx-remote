# Onyx Integration Notes

Source of truth for every wire-level detail this app depends on. Every address,
port, and command below was pulled from Obsidian's published docs and verified
by fetching the primary source directly (not paraphrased from a search
result). Where the primary source is silent, that's marked `TODO(verify)` and
also listed in `docs/PLAN.md` under Open Questions — nothing here is guessed.

Primary sources fetched for this doc:

- OSC setup page: `https://support.obsidiancontrol.com/Content/Onyx_Manual/Networking/OSC.htm`
- **OSC Mapping V1.20-Revision 5.pdf** (the actual command list, linked from the page above):
  `https://files.obsidiancontrol.com/s/yndNn7FsaB9Fyay` — saved locally at fetch time, 29 pages.
- Command Line Reference: `https://support.obsidiancontrol.com/Content/Onyx_Manual/Commandline/Commandline_Reference.htm`
- CITP: `https://support.obsidiancontrol.com/Content/Onyx_Manual/Networking/CITP.htm`
- Patch Import: `https://support.obsidiancontrol.com/Content/Onyx_Manual/Patch/Patch_Import.htm`
- Telnet: `https://support.obsidiancontrol.com/Content/Onyx_Manual/Networking/Telnet.htm`
- Telnet and UDP Commands: `https://support.obsidiancontrol.com/Content/Onyx_Manual/Networking/Telnet_and_UDP_Commands.htm`

Onyx manual revision referenced: RoboHelp export dated 2025, OSC mapping
revision "V1.20-Revision 5".

---

## 1. OSC

### 1.1 Transport, ports, addressing — what's actually documented

- Onyx OSC runs over the console's **REMOTE** network adapter (a distinct
  interface from EtherDMX, used for CITP/Art-Net).
- The console is configured with one or more **OSC Devices**. Each device
  entry has: a name, the **remote device's IP address**, and an **Incoming
  Port**. The doc's only instruction is *"Ensure the Incoming Port used by the
  OSC device matches the settings on the iPad."* — i.e. **you pick the port
  when you configure the OSC Device on the console, and your app must use the
  same port.** No default port number is published anywhere in the OSC setup
  page or the 29-page mapping PDF.
  - `TODO(verify)`: the actual default/suggested port Onyx pre-fills when you
    add a new OSC Device. Needs a hands-on look at the console's OSC page, or
    for you to tell us the port you already use with another OSC controller.
- No document states whether Onyx **sends** OSC from the same UDP socket it
  **receives** on, or from a separate ephemeral port. TouchOSC-style bidirectional
  setups generally assume symmetric IP:port, so `OnyxKit`'s transport should
  support configuring a distinct send port from the receive port, defaulting
  them equal, and must be validated against a real console before v1 ships.
  `TODO(verify)`.
- OSC is licensed: *"When using a PC, there are some restrictions on OSC in
  FREE and NOVA mode... OSC is locked unless you start a free trial."* This is
  a PC/software-Onyx licensing note, not a protocol detail, but it means our
  mock server must be able to simulate "OSC locked" so we can build/test that
  UI state. `TODO(verify)` exact behavior when OSC is locked (connection
  refused vs. silently no-op).
- **Playback control additionally requires its own license**, independent of
  general OSC being enabled — the mapping PDF states under the Playback
  section header: *"For playback execute messages a license is required."*
  Same statement repeats under Playback Pages. This is a real risk to the
  Cues screen and is called out in `docs/PLAN.md`.

### 1.2 Address/argument conventions

Every control in the mapping PDF is documented as a pair of address families:

- **Update Address** — sent **by Onyx to the remote** (feedback: LED
  on/off/blink state, LED color, button/label text, fader value). This is
  what our `ConsoleAdapter` should treat as inbound state.
- **Execute Address** — sent **by the remote to Onyx** to trigger the action
  (almost always `up/down`, i.e. send `1` on key-down, `0` on key-up, matching
  physical button press/release; faders send a `float` 0–255).

This maps directly onto the app's action vocabulary: `pressKey` sends an
Execute Address with value `1` (and should send `0` on release to mirror a
real button, since the protocol models press/release, not a single trigger).
`OnyxKit` must model both halves, not just fire-and-forget the `1`.

All addresses use root `/Mx/...` (the `x` looks like a fixed literal, not a
device index — the PDF never varies it). `TODO(verify)` whether `/Mx` changes
with the `deviceSpace` configuration value described in §1.9.

### 1.3 Command Line (status feedback only — no text-injection address)

| Address | Type | Direction | Meaning |
|---|---|---|---|
| `/Mx/commandLine/0001/color` | color | Update (Onyx→remote) | command line status swatch color |
| `/Mx/commandLine/0001/text` | string | Update | status word, e.g. `FREE` |
| `/Mx/commandLine/0001/text/color` | color | Update | status text color |
| `/Mx/commandLine/0002/color` | color | Update | command text background color |
| `/Mx/commandLine/0002/text` | string | Update | the literal command line text as typed on console |
| `/Mx/commandLine/0002/text/color` | color | Update | command text color |

**Important finding:** there is no documented Execute/inbound OSC address to
inject arbitrary command-line text (e.g. no "send the string `1 THRU 10 @
FULL`" message). The only way to drive the command line over OSC is to send
individual **Keypad** button presses (§1.7) one at a time, exactly like
pressing physical NX K keys. This confirms the app design: the virtual
keypad *is* the OSC command-line input method, not a shortcut for one. The
command line text shown in our Keypad screen should be driven by mirroring
`/Mx/commandLine/0002/text` feedback, not by locally predicting it — Onyx is
the source of truth for what the command line contains.

### 1.4 Playback (main playback faders 1–20) — license required

Each of the 20 main playbacks repeats the same 5-control pattern at a
per-playback base address. Playbacks 1–10 use bases `4201, 4211, ... 4291`;
playbacks 11–20 reuse the pattern at `4601, 4611, ... 4691` (offset +400,
*not* a continuation of 42xx — verified from the PDF, not inferred).

Per playback `N` (example shown for playback 1, base `4201`):

| Address | Type | Direction | Name in PDF |
|---|---|---|---|
| `/Mx/button/4201` | up/down | Execute | PFA 1 |
| `/Mx/button/4201/led`, `/led/color`, `/led/blink` | int/color/int | Update | PFA 1 |
| `/Mx/button/4202` | up/down | Execute | PFB 1 |
| `/Mx/button/4202/led`, `/led/color`, `/led/blink` | — | Update | PFB 1 |
| `/Mx/fader/4203` | float (0–255) | Execute + Update | LEVEL PLAYBACK 1 |
| `/Mx/fader/4203/color` | color | Update | fader color |
| `/Mx/button/4204` | up/down | Execute | PFC 1 |
| `/Mx/button/4204/text`, `/color`, `/text/color` | string/color | Update | PFC 1 (shows playback **name**) |
| `/Mx/button/4205` | up/down | Execute | PFD 1 |
| `/Mx/button/4205/led`, `/led/color` | int/color | Update | PFD 1 |

**`TODO(verify)` — critical for the Cues screen:** the PDF gives these buttons
generic labels "PFA/PFB/PFC/PFD" with no stated function (Go? Pause? Flash?
Release?). Nothing in the document says which one is GO and which is
Release. This must be confirmed against a real console (or Obsidian support)
before wiring the Cues screen's GO/Release buttons to these addresses. Until
verified, `MockConsoleAdapter` should treat the mapping as configurable/unknown
rather than hardcoding a guess.

Master/Flash/Group faders (unambiguous, separate address block):

| Address | Type | Name |
|---|---|---|
| `/Mx/button/2201` (+`/led*`) | up/down | GRAND MASTER FLASH |
| `/Mx/fader/2202` | float 0–255 | GRAND MASTER LEVEL |
| `/Mx/button/2211` (+`/led*`) | up/down | FLASH MASTER FLASH |
| `/Mx/fader/2212` | float 0–255 | FLASH MASTER LEVEL |
| `/Mx/button/2221` (+`/led*`) | up/down | GROUP MASTER A FLASH |
| `/Mx/fader/2222` | float 0–255 | GROUP MASTER A LEVEL |
| `/Mx/button/2231` (+`/led*`) | up/down | GROUP MASTER B FLASH |
| `/Mx/fader/2232` | float 0–255 | GROUP MASTER B LEVEL |

Playback bank paging (5 visible banks, pageable):

| Address | Type | Name |
|---|---|---|
| `/Mx/button/4412` | up/down | Bank Page Up |
| `/Mx/button/4413` | up/down | Bank Page Down |
| `/Mx/button/4421`…`/4425` (+`/text`, `/color`) | up/down / string / color | Playback Bank 1–5 |
| `/Mx/label/4401/text` (+`/color`, `/text/color`) | string/color, Update only | Playback Bank Number |
| `/Mx/scroll/4110/up`, `/down` | up/down | Bank Scroll Up/Down |
| `/Mx/scroll/4411/up`, `/down` | up/down | Bank Page Scroll Up/Down |
| `/Mx/button/4600` | up/down | Fader Swap |

Global playback buttons:

| Address | Name |
|---|---|
| `/Mx/button/5502` | SELECT |
| `/Mx/button/5503` | RELEASE |
| `/Mx/button/5504` | BEAT |
| `/Mx/button/5511` | SNAP |
| `/Mx/button/5512` | `\|\|/Back` (pause/back) |
| `/Mx/button/5513` | GO |

These global GO/RELEASE/SNAP/BACK buttons operate on the **currently
selected** playback/cuelist (selection model documented in the Command Line
reference, §2.6) — they are not per-playback-number addresses. This is a much
safer bet than PFA–PFD for a generic "Go" / "Release" action in the UI, since
their names are explicit, but it means the app must track/set which
playback is "selected" before calling them. `TODO(verify)` exactly how OSC
selects a target playback (there's no documented `/Mx/.../select/<n>`
address — selection may only be settable from the console itself, or via the
per-playback PFC "SELECT" default behavior mentioned in the Command Line
doc's "Playback Select" section, which is ambiguous over OSC).

**Playback Pages (separate, explicitly self-documenting, license required):**

```
/Mx/playback/page<pageIndex>/<buttonIndex>/<action>
```

- `pageIndex`: 1–100 (1-based)
- `buttonIndex`: 0–99 (0-based)
- `action` (string, case-insensitive; sent as the OSC address suffix, value `1`
  for key-down): `go`/`play`, `pause`, `release`, `select`, `snapgo`,
  `toggle`, `back`

Examples straight from the PDF:
```
/Mx/playback/page1/0/go 1        → key-down GO on page 1, button 1
/Mx/playback/page5/9/release 1   → key-down RELEASE on page 5, button 10
```

This is unambiguous and is the recommended target for the Cues screen's GO
and Release buttons **if the console has the Playback Pages license**; the
PFA–PFD main-fader block above is the fallback if it doesn't, pending the
`TODO(verify)` on PFA–PFD semantics. This choice is called out as an open
question in `docs/PLAN.md`.

### 1.5 Screens (Views)

| Address | Name |
|---|---|
| `/Mx/button/1101`…`/1108` | VIEW 1–8 |
| `/Mx/button/3101`…`/3108` | VIEW 9–16 |

Each is `up/down` Execute + `led`/`led/color`/`led/blink` Update, same pattern
as every other button in this document.

### 1.6 Master/Programmer

| Address | Name |
|---|---|
| `/Mx/button/6001` | **HIGHLIGHT** |
| `/Mx/button/6003` | CV (capture value?) |
| `/Mx/button/6401` | Last |
| `/Mx/button/6402` | Next |
| `/Mx/button/6411` | Swap Programmer |
| `/Mx/button/6108` | Link (Execute only, no Update documented) |
| `/Mx/button/6101`…`/6105` (+`/text`) | BASE CHANNEL GROUP 1–5 |
| `/Mx/button/6111`,`6121`,`6131`,`6141` | BASE CHANNEL 1–4 |
| `/Mx/button/6201`…`/6205` (+`/text`) | EFFECT CHANNEL GROUP 1–5 |
| `/Mx/button/6211`,`6221`,`6231`,`6241` | EFFECT CHANNEL 1–4 |
| `/Mx/belt/6112`,`6122`,`6132`,`6142` | VALUE BASE 1–4 (encoder belts) |
| `/Mx/belt/6212`,`6222`,`6232`,`6242` | VALUE EFFECT 1–4 (encoder belts) |

**This directly answers how Locate/Test-channels should work:** `/Mx/button/6001`
is the documented HIGHLIGHT toggle — the same mechanism the console's own
"Highlight" state uses (per the Command Line reference: *"Selected fixtures
assume the Highlight state which usually is Open White with Intensity at
100%"*). The app's **Locate** action should select the target fixture(s) then
toggle HIGHLIGHT on, and turn it off when done (or after a timeout) — never
invent a separate "locate" address. **Test channels** has no dedicated OSC
address; it must be built from the same primitives (select fixture, set
individual parameter values), not a single console command. `TODO(verify)`
whether there's a better built-in "test channels" flow in the console UI we
should mirror.

**Critical limitation for the Position screen:** the belt/encoder addresses
(`/Mx/belt/...`) are typed `up/down`, i.e. **relative increment/decrement
pulses**, not absolute value messages. There is no documented OSC address to
set Pan/Tilt (or any parameter) to an exact numeric value directly — the only
way to reach an exact value over OSC is to drive the numeric keypad (§1.7) to
type the number and press the parameter/`@` key, exactly like a human would
on the console. This matches (and explains) the prompt's own note that
"Exact values are entered through the Keypad" on the Position screen — it
isn't a UX choice, it's a protocol constraint. The Position screen's
pan/tilt sliders will have to translate a drag gesture into a stream of
belt up/down pulses (coarse) and rely on the Keypad for exact numeric entry
(precise) — `PatchKit`/`OnyxKit` should not pretend a slider can send one
absolute-value message.

### 1.7 Keypad (virtual NX K) — this is the real command-line input mechanism

| Address | Name |
|---|---|
| `/Mx/button/2001` | MACRO |
| `/Mx/button/2002` | PREVIEW |
| `/Mx/button/2003` | MENU |
| `/Mx/button/4321` | FADE |
| `/Mx/button/4322` | DELAY |
| `/Mx/button/4331` | SNAPSHOT |
| `/Mx/button/4332` | BANK |
| `/Mx/button/5101` | EDIT |
| `/Mx/button/5102` | UNDO |
| `/Mx/button/5103` | CLEAR |
| `/Mx/button/5104` | COPY |
| `/Mx/button/5106` | MOVE |
| `/Mx/button/5107` | DELETE |
| `/Mx/button/5401` | RECORD |
| `/Mx/button/5402` | UPDATE |
| `/Mx/button/5411` | LOAD |
| `/Mx/button/5412` | GROUP |
| `/Mx/button/5413` | CUE |
| `/Mx/button/5200`…`/5209` | digits `0`–`9` |
| `/Mx/button/5210` | `-` |
| `/Mx/button/5211` | `+` |
| `/Mx/button/5212` | `.` |
| `/Mx/button/5213` | Enter |
| `/Mx/button/5214` | `/` |
| `/Mx/button/5215` | Backspace |
| `/Mx/button/5216` | `@` |
| `/Mx/button/5301` | Full |
| `/Mx/button/5302` | Through (Thru) |

`TODO(verify)`: **`5105` (where `COPY`=5104 and `MOVE`=5106 would suggest a
gap) is absent from the PDF** — not a typo on our part, the document simply
skips it. Also absent from this list: `SWAP PROG`, `LINK`, `LAST`, `NEXT`,
`SNAP SHOT`/`HIGH LIGHT` as drawn on the physical NX K (some of these exist
under different addresses elsewhere — e.g. `Last`/`Next` are `6401`/`6402`
under Programmer, `HIGHLIGHT` is `6001`). Before wiring every key on the
Keypad screen's mock layout, cross-check each physical key against this list;
any key with no documented address is `TODO(verify)` and must degrade
gracefully (disabled, not silently broken) rather than sending a guessed
address.

Programmable F-Keys: `/Mx/button/5601` (F1), `/Mx/button/56A1` (F2),
`/Mx/button/5602` (F3), `/Mx/button/56A2` (F4), `/Mx/button/5603` (F5),
`/Mx/button/56A3` (F6), `/Mx/button/2101` (F7), `/Mx/button/21A1` (F8),
`/Mx/button/2102` (F9), `/Mx/button/21A2` (F10), `/Mx/button/2103` (F11),
`/Mx/button/21A3` (F12) — all `up/down` + standard `led`/`led/color`/`led/blink`
Update triplet. F-key groups/paging: `/Mx/button/5701`…`/5705` (+`/text`),
`/Mx/scroll/5706/up`, `/down`.

Navigation (used for menu/list navigation on console, may be useful for our
own on-screen affordances but not required for v1):
`/Mx/button/7301` (Up), `7302` (Left), `7303` (Down), `7304` (Right),
`7001` (TRACKFUNC P/T), `7004` (MODE).

### 1.8 Encoder belts — direction confirmed relative, not absolute

Covered above in §1.6; repeated here because it governs both the Keypad
screen's four touch encoders and the Position screen's pan/tilt sliders: all
`/Mx/belt/...` execute addresses are `up/down`. Treat every physical/virtual
encoder as a relative-pulse generator. `ConsoleKit`'s action vocabulary
should expose something like `nudge(parameter, direction)` in addition to
`setValue(param)`, and `OnyxKit`'s Onyx adapter should implement `setValue`
by composing keypad digit presses rather than pretending a single OSC message
can carry an absolute value.

### 1.9 Configuration

| Address | Type | Direction | Name |
|---|---|---|---|
| `/Mx/configuration/deviceSpace` | string | Update | Device Space ID Number |
| `/Mx/configuration/deviceSpace/down`, `/up` | up/down | Execute | Device Space ID Number |

`TODO(verify)`: what "Device Space" means in this context (multi-console
sync? a numbered remote-device slot?) and whether it affects the `/Mx` root
used everywhere else. Not needed for v1; flagged for later if multi-console
setups come up.

---

## 2. Command Line Reference (for building `OnyxKit`'s higher-level helpers)

The full reference was fetched and read in its entirety
(`Commandline_Reference.htm`). Summary of the parts this app actually needs;
anything not listed below (Grouping tools, Conditional Fixture Selection,
Cuelist Options editor, Timecode cuelists, F-Key editing) is out of scope for
v1 and intentionally omitted here rather than guessed at.

### 2.1 Fixture selection

```
1 ENTER                 select fixture 1
1 + 10 ENTER             select fixture 1 and 10
1 THRU 10 ENTER          select fixtures 1-10
1 THRU 10 - 8 ENTER      select 1-10 except 8
+ 15 ENTER               add fixture 15 to selection
- 7 ENTER                remove fixture 7 from selection
GROUP 8 ENTER            select Group 8
- GROUP 5 ENTER          deselect Group 5
. ENTER                  select all fixtures in the programmer
0 ENTER                  deselect all
. 0 ENTER                select every patched fixture in the show
/ ENTER                  invert selection
```

### 2.2 Intensity / parameter values

```
[SELECTION] FULL                       set intensity 100%
[SELECTION] @ 25 ENTER                 set intensity 25%
[SELECTION] @ + 15 ENTER               add 15% intensity
[SELECTION] @ - 25 ENTER               subtract 25% intensity
[SELECTION] @ 0 THRU 100 ENTER         fan intensity 0→100% across selection
[SELECTION] @ <ParamGroup> <#> ENTER   select preset # in a parameter group, e.g. "@ Color 10 Enter"
[SELECTION] @ <ParamButton> <#> ENTER  assign a value to a specific parameter, e.g. "@ Magenta 50 Enter"
```

### 2.3 Record / Update / Clear (what the app's Record/Update/Clear buttons send)

```
RECORD [PLAYBACK SELECT]         append a cue to the end of the given playback
RECORD CUE # ENTER               record to a specific cue number in the selected cuelist
RECORD GROUP # ENTER             create/merge a fixture group
RECORD PRESET <button>           create/merge a preset
UPDATE                           trace programmer values back into cues/presets that use them (press twice to confirm)
CLEAR ENTER                      clear values from selected fixtures in the programmer
CLEAR CLEAR                      (hold) clear all values + all selection from the programmer
```

### 2.4 Patch (command line) — confirms exactly what the prompt states

```
115 @ 401 ENTER                  patch fixture 115 to address 401
115 @ / 5 ENTER                  patch fixture 115 to next free address on universe 5
115 THRU 121 @ 5 ENTER           patch fixtures 115-121 starting at address 5
115 @ (AutoAddress)              patch fixture 115 at next available address
CLEAR 101 ENTER                  unpatch fixture 101 (remove its DMX address)
CLEAR 101 @ 15 ENTER             remove address 15 from fixture 101
CLEAR /5 ENTER                   unpatch every fixture in universe 5
DELETE 101 ENTER                 delete fixture 101 from the showfile entirely (not just unpatch)
MOVE 1 @ 5 ENTER                 renumber fixture ID 1 to ID 5
MOVE 1 THRU 10 @ 51 ENTER        renumber fixtures 1-10 starting at ID 51
COPY 1 @ 301                     clone all cue/preset/group values from fixture 1 to new fixture 301
```

**Adding brand-new fixtures requires choosing a fixture TYPE first** — the
reference explicitly frames this as a UI gesture, not pure text entry:
*"Choose TYPE — Fixture type from existing fixtures in show or new types out
of fixture library"*, then e.g. `RECORD 20 <TYPE> (AutoID) ENTER`. There is
no text-only command that both names an arbitrary fixture type from the
library and creates fixtures — confirms the prompt's constraint. Our virtual
keypad cannot add brand-new fixture types to Onyx; it can only re-address,
unpatch, renumber, or clone fixtures that already exist in the Onyx showfile.

### 2.5 Cue navigation

```
CUE # ENTER            go to cue # on the selected cuelist (normal timing)
SNAP + CUE # ENTER     go to cue # instantly (zero time)
```

### 2.6 Playback selection (governs what global GO/RELEASE/SNAP act on)

The "selected" cuelist/playback is whatever was last touched via a main
playback fader, button module, submaster flash button, or cuelist directory
button — there is no single documented OSC "select playback N" address (see
§1.4's open question). This is a genuine gap between the console's touch
model and what OSC alone can drive; flagged in Open Questions.

---

## 3. Telnet / UDP — a second, simpler control channel

Fully separate from OSC. Source:
`Telnet_and_UDP_Commands.htm` (linked from `Telnet.htm`).

- Requires **Onyx 4.10 or later**.
- Runs over a **configurable TCP/IP port** you assign when enabling the
  Telnet server on the console (the doc's own example uses port `2323`, but
  that is explicitly an *example*, not a default — same caveat as OSC's port).
  `TODO(verify)` the real default, if any.
- Available over **both TCP (Telnet) and UDP**. Telnet connections receive a
  response to each command; **UDP sends get no response at all** — so UDP is
  fire-and-forget, matching the OSC playback license concern (an unlicensed
  or misconfigured console would fail silently over UDP).
- Commands are plain ASCII strings terminated with a carriage return. Full
  list, verbatim:

| Command | Syntax | Example |
|---|---|---|
| Clear | `CLRCLR` | `CLRCLR` (presses Clear twice — clears the programmer) |
| Go Cuelist | `GQL #` | `GQL 14` |
| Release Cuelist | `RQL #` | `RQL 14` |
| Pause Cuelist | `PQL #` | `PQL 4` |
| Go To Cue | `GTQ #,#` | `GTQ 14,3` or `GTQ 14,4.1` (cuelist, cue — supports point cues) |
| Release All Overrides | `RAO` | `RAO` |
| Release All Cuelists, Dimmer First | `RAQLDF` | `RAQLDF` |
| Release All Cuelists and Overrides | `RAQLO` | `RAQLO` |
| Release All Cuelists | `RAQL` | `RAQL` |
| Set Cuelist Level | `SQL #,#` | `SQL 12,255` (cuelist, level 0-255) |

**This is a real, documented alternative to OSC for playback triggering by
cuelist number** — and unlike the OSC main-playback block, these commands are
self-explanatory and not gated by the "requires a license" language that
appears in the OSC mapping PDF's Playback section (the Telnet page makes no
mention of any license requirement). This makes Telnet/UDP a strong
candidate for `ConsoleKit`'s `go`/`release` actions if the OSC playback
license turns out to be unavailable — worth prototyping both in M1 rather
than committing to OSC alone. **No query/status/feedback commands are
documented on this channel** — it's trigger-only, so it cannot serve as our
"read cuelist status" gap-filler; that gap remains open (see below).

---

## 4. CITP

Source: `CITP.htm` + `Patch_Import.htm`.

- CITP integration in Onyx is aimed at **media servers/visualizers**: Onyx
  auto-detects media servers on the network and syncs **media thumbnails**
  into parameter belts once "DMX patch information match up on both" sides.
  This is fundamentally a media-server-sync feature, not a general-purpose
  bidirectional patch API.
- Configuration lives under Settings → Network → Interfaces → the
  **EtherDMX** interface (not the REMOTE interface OSC uses) → CITP tab.
- *"CITP can also be used to import patch from compatible visualizers and
  other tools"* — confirmed, but the only description of the actual
  mechanism is UI-driven: from the Patch screen's Import page, press **"Scan
  over CITP"**, review the resulting patch sheet, then **Import Selected** or
  **Import All**. There is no documented network trigger to kick off a CITP
  scan remotely, nor a documented CITP message schema (PInf/MSex module
  details are not published by Obsidian — CITP itself is an open, published
  protocol, but Onyx's page doesn't say which parts it implements). Treat any
  CITP client implementation as needing protocol-level testing against a real
  console, not just the public CITP spec, before trusting it.
- **Separately, and much more concretely documented:** Onyx has its own
  **native patch XML export/import**, independent of CITP entirely — *"Any
  ONYX show may export its patch via the Main Menu and Show Settings Menu,
  under 'Patch Tasks'"*, producing an XML file, which is re-imported via
  **"Read ONYX Patch"** on the Import page (same Import Selected/Import All
  flow). This is a genuinely promising, documented, non-CITP path for
  getting `PatchKit`'s patch model into Onyx: have the app **write an
  Onyx-compatible patch XML file** that the user imports on the console. The
  XML schema itself is not published — we don't have a sample file to reverse
  engineer yet. `TODO(verify)`: get one real exported patch XML from Onyx (you
  running Show Settings → Patch Tasks → Export on your own console) so we can
  target that format instead of CITP for M4, or as a fallback if CITP proves
  too hard to reach without a device to test against.
- No default patch conflict resolution beyond: *"If the visualizer or tool
  that is connected does not have a perfect fixture match, ONYX will select
  the best fit, however you may change this."* Import always goes through
  Onyx's own conflict-checking pass regardless of source (native XML or
  CITP).

---

## 5. Summary of everything marked `TODO(verify)` (also mirrored in `docs/PLAN.md`)

1. Default/suggested OSC Incoming Port on a fresh OSC Device (none published).
2. Whether Onyx sends OSC feedback from the same port it receives on.
3. Exact behavior when OSC is unlicensed/locked (refused vs. silent no-op) —
   needed to build a faithful mock.
4. Which physical action each of PFA/PFB/PFC/PFD maps to on the main
   playback block (`/Mx/button/42x1..42x5` and `/Mx/button/46x1..46x5`).
5. Whether/how OSC can select which playback the global SELECT/GO/RELEASE/
   SNAP/BACK buttons act on.
6. Whether the console's Onyx license includes "Playback" and/or "Playback
   Pages" OSC control (both explicitly gated in the mapping PDF).
7. Whether Keypad keys with no documented OSC address (Swap Prog, Link — Link
   does exist at `6108` — double check the rest against the physical NX K)
   have any other reachable address, or must be disabled in the UI.
8. Default/example-only Telnet port — no stated default.
9. The Onyx native patch XML schema (need one real exported sample file).
10. CITP message-level details beyond "it syncs thumbnails and can import
    patch" — no published address/port/module list.
11. Any mechanism to read live cue list contents/state (names, times,
    running/next) beyond the coarse per-playback name/level/LED feedback in
    §1.4 and the Command Line's own status text. Nothing found. This directly
    limits how much of the Cues screen's mockup (per-cue Now/Next list with
    timing) can be console-driven in v1 versus locally-authored data.

# Stallage — Build Specification

> Portfolio app 72, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Scan a barcode or QR to see which stall holds a belonging and who last received it.

| Field | Value |
| --- | --- |
| Product name | Stallage |
| Bundle identifier | `com.stallage.crib` |
| Domain | https://stallage-crib.pro |
| Contact URL | https://stallage-crib.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `slg_` |
| User-Agent | `Stallage/1.0 (iOS; +https://stallage-crib.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Stallage -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A keeper scans a barcode or QR into the open stall so each tagged belonging shows where it sits and who last received it.

### 2.1 User flow

1. Scan a barcode or QR into the open stall
2. Name a new Tag in place when the code was unknown
3. Switch stall or scan a stall QR and scan the same Tag to hop it
4. Read status from the stall duty; Lent writes issued and assignedTo
5. Open the Lifecycle segment for hops, trail and overdue issued Tags
6. Print or share a QR for a Tag or Stall
7. Add or rename stalls in Settings

### 2.2 Essential behaviour

- Scan add: unknown code writes a Tag in the open stall
- Status from stall Duty: inStock, issued, repair, relinquished
- Transfers as Hop, TrailMark and assignedTo
- Categories as named stalls
- Overdue: issued longer than 30 days on Lifecycle
- Local QR from code or id; no remote catalog
- Undo peels the last Hop or the Tag if it has none

---

## 3. Uniqueness assignment for Stallage

| Axis | Assigned value |
| --- | --- |
| Architecture | **Seat-hop encoding (a new scan writes Tag and Seat on the open Stall; a known scan onto a different Stall writes Hop and TrailMark and assignedTo; Duty copies onto status; Relinquished freezes the Tag; issued older than 30 days ranks overdue)** |
| UI approach | **SwiftUI pure · take barcodeinventory** |
| Naming convention | **Crib / stall lexicon** |
| File organization | **By crib role (Crib, Stall, Tag, Hop, TrailMark)** |
| Dependency strategy | **None** |
| Design direction | **Lavender calm journal** |
| Typography | **SF Pro** |
| Navigation pattern | **Crib-segment chrome (the crib never leaves; Inventory Lifecycle and Settings are segments on one screen; scan and hop fuse on Inventory)** |
| AI art style | **3D glass render glassmorphism · take barcodeinventory** |
| Functional twist | **Stall-then-hop (a new scan writes a Tag into the open stall; a known scan into another stall writes a Hop and a TrailMark; Relinquished freezes hops)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — barcode_inventory

**Core** — A keeper scans a barcode or QR into the open stall so each tagged belonging shows where it sits and who last received it.

**Audience** — People who label tools, cables, cameras or costumes and need to know who holds them, not a warehouse.

**User flow**

1. Scan a barcode or QR into the open stall
2. Name a new Tag in place when the code was unknown
3. Switch stall or scan a stall QR and scan the same Tag to hop it
4. Read status from the stall duty; Lent writes issued and assignedTo
5. Open the Lifecycle segment for hops, trail and overdue issued Tags
6. Print or share a QR for a Tag or Stall
7. Add or rename stalls in Settings

**Essential features**

- Scan add: unknown code writes a Tag in the open stall
- Status from stall Duty: inStock, issued, repair, relinquished
- Transfers as Hop, TrailMark and assignedTo
- Categories as named stalls
- Overdue: issued longer than 30 days on Lifecycle
- Local QR from code or id; no remote catalog
- Undo peels the last Hop or the Tag if it has none

**Twist** — Stall-then-hop. Home is the crib. Inventory, Lifecycle and Settings are segments on one screen. The open stall is the landing. Scanning an unknown code writes a Tag into that stall, copies its Duty onto status, and fuses a name in place. Scanning a Tag that already sits in a different stall writes a Hop, a TrailMark, assignedTo, and moves it; Lent writes issued. Scanning a Tag already in the open stall focuses it and does not duplicate. Relinquish freezes that Tag; new scans still seat. A Tag whose status has been issued for more than 30 days ranks on Lifecycle. Undo peels the last Hop, or the Tag if it has none. Home verb: hop-the-tag, not edit-a-row. QR is code if present else id. Search is local. No food catalog.

**Why this is not a repeat** — barcode_inventory has not shipped. Home is a crib of stalls where the same scan either seats or hops, not an AssetList with a transfer form. This is not ForkTrace (no product timeline and no Open Food Facts), not MacroDock or pantry_expiry (no grams, slots, kcal or best-before rail), not cost-per-use, and not a cocktail bottle bar. The live capture session is the product; cgi search.pl is a leftover and must stay dark. Single-screen segments replace the last ten tab chromes. After seed the scan control stays enabled.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Search + scan bar, status chips, asset cards.
- Invariant: Scan finds or creates draft inStock. Transfer writes TransferRecord, assignedTo, status issued. issued>30d = overdue. QR = code ?? id.
- Never: Camera denied → Settings. No Sweep game feeding real KPIs.
- Taste DNA is section 7.6. Do not invent a second look.
- Scan: AVFoundation + Vision; symbologies include `.qr`; digit runs 8–14 from QR/URL; UPC-A pad; Simulator chips + manual; stop session. Pre-permission CTA is Continue or Next (Guideline 5.1.1 — never Allow/Enable camera).

### 3.1 Architecture contract

Seat-hop encoding is the store. A new scan on the open stall writes a Tag and a Seat, copies that stall Duty onto status, and fuses a name in place. A known Tag scanned onto a different stall writes a Hop, a TrailMark, assignedTo, and moves the Seat. Lent copies issued onto status and writes assignedTo. Relinquished freezes hops on that Tag while new scans still seat other Tags. Issued longer than 30 local days ranks overdue on Lifecycle, using Calendar.current.startOfDay folded to an Int YYYYMMDD daykey. Undo peels the last Hop, or the Tag if it has none. A scan of a Tag already seated in the open stall focuses it and does not duplicate.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

100 percent SwiftUI. The only UIViewRepresentable is the AVCaptureMetadataOutput preview. Take barcodeinventory density: local search plus scan bar, status chips, belonging rows on the open stall. Do not copy Asset, TransferRecord, AssetList, Sweep, or WebView type names or layouts. Compose a journal page: hairline stall rail, ink lines not a card grid, writing surface using remaining height. Filled-capsule scan control. Shadow elevation from the kit. Glass renders are cutout brand art, not a frosted UI. Scan and hop fuse on Inventory. Axis values never appear as titles. Native Button, Toggle, TextField. Full-width Continue or Next before requestAccess.

### 3.3 Naming contract

Convention: Crib / stall lexicon.

Examples to follow: `CribStore`, `openStall`, `seatTag(_:)`, `peelLastHop()`

### 3.4 Dependency contract

None. No SPM packages. project.yml has no packages key. No URLSession catalog. cgi search.pl is leftover and stays dark. Search filters Tag name and code in memory. QR is drawn on device from code if present else id. Settings Contact is https://stallage-crib.pro/contact-us as a tappable link, not a product WebView.

### 3.5 Navigation contract

Crib-segment chrome. The crib never leaves. Inventory, Lifecycle, and Settings are segments on one screen. Inventory is the landing: open stall, search, scan, hop. Lifecycle and Settings swap in place with a 180ms cross-fade, instant when Reduce Motion is on. Capture, name fusion, and stall QR are full screen covers over the crib, dismissed back to Inventory. No tab bar. No Scan tab. No Search tab. No Goals tab. After Simulator seed the scan control stays enabled.

### 3.6 Screen composition contract

Full screen covers. Physical screens: Inventory, Lifecycle, Settings. Inventory is the crib home (ReviewScreen today): open stall, local search, scan bar, duty chips, tag lines. Lifecycle is hops, trail, and overdue issued tags (ReviewScreen log). Settings is stall names, contact, and reset (ReviewScreen goals). Capture, name fusion, and QR share are full screen covers over Inventory. Onboarding is a cover stack with Continue at the bottom full width. Camera denied is a full page plus Open Settings. The three ReviewScreen keys must open these three different segments.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By crib role (Crib, Stall, Tag, Hop, TrailMark)**

```
Stallage/
  Crib/
  CribShell.swift
  CribStore.swift
  CribSegment.swift
  StallCapture.swift
Stall/
  Stall.swift
  StallDuty.swift
  OpenStallView.swift
Tag/
  Tag.swift
  Seat.swift
  TagLine.swift
Hop/
  Hop.swift
  HopUndo.swift
TrailMark/
  TrailMark.swift
  LifecycleView.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Inventory
A first-class screen for **Inventory**. Must render empty, populated and error states.

### 5.3 Lifecycle
A first-class screen for **Lifecycle**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


**Scan (camera families). Mechanics from the white book scanner — add `.qr`.**

Capture:
- AVFoundation session + Vision `VNDetectBarcodesRequest` (or `AVCaptureMetadataOutput` with the same set).
- Symbologies must include `.qr` plus `.ean13`, `.ean8`, `.upce` (Code 128/39/93 if the domain uses them). Linear-only misses QR packs and QR-encoded EANs.
- Permission: notDetermined → `requestAccess` (system alert is the first ask). A pre-screen is allowed only if the proceed button is **Continue** or **Next**.
- Guideline 5.1.1 reject: any CTA that directs the grant — `Allow camera`, `Enable camera`, `Grant camera`, `Allow camera access`, or a bare `Allow` / `Enable` / `Grant` on the button that calls `requestAccess`.
- Denied/restricted → copy + Open Settings (`UIApplication.openSettingsURLString`). Never a second Allow/Enable button.
- No capture device (Simulator): sample-code chips + mandatory manual field. Fully usable without a camera.
- Start the session on appear; `stopRunning` on disappear and on background.
- Cooldown 1.5–2.0 s after a decode. Skip frames (every 3rd is enough). Ignore the same payload while a lookup is in flight.
- Continuous autofocus / autoexposure when supported. `alwaysDiscardsLateVideoFrames`. Preview `resizeAspectFill`.

Payload (camera, typed, pasted URL):
- Keep digit runs of length 8–14. A QR/URL may be text — extract those runs; do not require the whole payload to be digits.
- 12-digit UPC-A → prefix `0`.
- Try every candidate before miss. EAN-8/13, UPC-A/E, QR carrying any of those.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Asset** — named per this app's convention.
- **Transfer** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Lavender calm journal**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#1D161A` | Screen background |
| `surface` | `#291E24` | Cards, rows, sheets |
| `ink` | `#F2EDF0` | Primary text and icons |
| `accent` | `#DD5F9E` | Primary action, key figure, progress fill |
| `muted` | `#A8949E` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via Font.system only. Calm body first. Display is reserved for the open stall name on the date rail, never for body copy. At most six steps behind one accessor: display, title, headline, body, caption, micro. Body is about 17pt. None larger than 34pt, never below 12pt, no Font.custom, no fixedSize. Weights carry hierarchy. Overdue days, hop counts, and issued spans go through NumberFormatter with tabular figures. Day edges use Calendar.current.startOfDay then fold to Int YYYYMMDD. Dynamic Type. At AX5 the stall rail still shows the name and the scan control stays hittable.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **20pt** for cards, sheets and primary surfaces; **12pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **shadow** — a single soft drop-shadow token, reused everywhere a surface sits above another.

Primary control: **filled capsule** — the primary CTA is a full-width filled `Capsule`, never a bare text link or a plain `.plain` button.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI pure · take barcodeinventory**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI pure · take barcodeinventory** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

### 7.6 Taste DNA

Aesthetic: **editorial** (Editorial: measure, rules, type hierarchy, almost no boxes.)

Reference system: **notion** — steal rhythm and restraint, not their colours or logos.

Mood: **journal**.

Home rhythm (`journal`, airy): Journal page, a date rail, an ink block. Lists are lines, not cards.

Quiet page. Hairline date rail. The writing surface uses remaining height. No dashboard chrome on home.

Type move: Calm body first; display only on the date or title.

Motion (`quiet`): Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap.

Voice (`warm`): Human and brief. Empty states invite. Errors stay calm and useful.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable CribDocument with schemaVersion, stalls, tags, hops, and trailMarks, JSON-encoded into UserDefaults under slg.crib.v1. CribStore is the in-memory source of truth. Debounce writes. Flush when scenePhase becomes inactive or background, and after hop, undo, relinquish, or reset. Decoding failure falls back to slg.crib.v1.backup, then an empty crib, never a crash. resetAllData() is reachable from Settings. Simulator seed writes several stalls and tags behind slg.demo.v1 once, marks onboarding complete, and leaves scan enabled. Never seed on a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Stallage/1.0 (iOS; +https://stallage-crib.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.productivity`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_NSCameraUsageDescription: Stallage uses the camera to read a barcode or QR on a tagged tool, cable, camera, or costume so it can be seated in a stall.
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.productivity
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Stall-then-hop (a new scan writes a Tag into the open stall; a known scan into another stall writes a Hop and a TrailMark; Relinquished freezes hops)

Stall-then-hop is the home verb. The crib never leaves. Inventory is the open stall and the live capture session, the place a scan either seats or hops. An unknown code writes a Tag here, copies Duty onto status, and fuses a name in place. A known code from another stall writes a Hop and a TrailMark, assignedTo, and moves it. Lent writes issued. Relinquished freezes hops on that Tag. QR is code if present else id. Search is local. cgi search.pl stays dark. After seed the scan control stays enabled.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **3D glass render glassmorphism · take barcodeinventory**


This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

Base prompt, reused and extended for every asset:

```
3D glass render, glassmorphism, frosted translucent stall crib, quiet journal still life, tagged tools cables cameras and costume tags seated in glass stalls, soft studio light, refraction, no text, no captions, no letters, no emoji, no UI chrome
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `slg_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `slg_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `slg_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `slg_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `slg_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `slg_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `slg_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `slg_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `slg_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `slg_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `slg_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Stall-then-hop (a new scan writes a Tag into the open stall; a known scan into another stall writes a Hop and a TrailMark; Relinquished freezes hops)' feature screen. |
| 11 | `slg_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `slg_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`slg_AppIcon`** — 1024x1024

```
A single glass crib stall filling the square canvas, 3D glass render, one tagged tool silhouette hanging inside a frosted pane, subject in the center 80 percent, no text, no letters, no rounded-corner mask, no drop shadow leaving the canvas, opaque, no alpha
```

**`slg_Splash`** — 1290x2796

```
Tall quiet glass crib, frosted stalls receding, uncluttered centre band for a wordmark, 3D glass render, no text in the image, no letters
```

**`slg_Onboarding1`** — 1024x1536

```
Cutout of a keeper holding a tagged cable beside a small glass stall, isolated on transparent ground, 3D glass, all four corners transparent, no square plate

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slg_Onboarding2`** — 1024x1536

```
Cutout of a barcode tag being seated into an open glass stall mouth, mid-gesture, isolated, transparent corners, no plate, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slg_Onboarding3`** — 1024x1536

```
Cutout of two glass stalls with one tagged belonging hopping between them, isolated, transparent corners, no plate, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slg_EmptyHome`** — 1024x1024

```
Cutout of an empty open glass stall waiting, quiet, inviting, isolated on transparent ground, all four corners transparent, no plate

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slg_EmptyList`** — 1024x1024

```
Cutout of a blank journal leaf with a faint empty trail, isolated, transparent corners, no plate, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slg_CardBackdrop`** — 1200x800

```
Soft abstract glass stall panes filling the canvas, low contrast, no text, no letters, suitable behind ink
```

**`slg_ControlFace`** — 512x512

```
Cutout face of a filled-capsule scan control as a small glass stall mouth, isolated, transparent corners, no plate, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slg_TwistHero`** — 1024x1024

```
Cutout emblem of a tagged belonging hopping from one glass stall to another, isolated, transparent corners, no plate, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slg_SuccessMark`** — 512x512

```
Cutout of a small glass check seated in a stall mouth, isolated, transparent corners, no plate, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slg_HeaderDecor`** — 1200x600

```
Wide quiet glass hairline rail ornament, journal date-rail feel, low contrast, no text, no letters

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated subject, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`slg.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `StallageTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Stallage -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Seat-hop encoding (a new scan writes Tag and Seat on the open Stall; a known scan onto a different Stall writes Hop and TrailMark and assignedTo; Duty copies onto status; Relinquished freezes the Tag; issued older than 30 days ranks overdue)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI pure · take barcodeinventory**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Crib-segment chrome (the crib never leaves; Inventory Lifecycle and Settings are segments on one screen; scan and hop fuse on Inventory)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Stallage
xcodegen generate
xcodebuild -scheme Stallage -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Stallage -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.

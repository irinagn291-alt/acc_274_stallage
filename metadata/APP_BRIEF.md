<!-- gf-brief source=7a3a94666bd0fd6cafba2ff9cc290911e25c1c6ecccefdb408d985a7f714428d written=2026-09-26T02:17:31+03:00 -->
# Stallage

## What it is
Stallage is a dark, on-device crib for production and costume gear: belongings live in named stalls as Tags. You scan a barcode or QR to seat an unknown code in the open stall, or hop a known Tag from another stall and keep a trail of who received it. It is for people who need to know where a tool, cable, camera, or costume sits and who last took it.

## Launch and onboarding
Cold launch shows a brief dark screen (spinner if loading is slow). A system notification permission prompt may appear near launch. If onboarding is unfinished, a full-screen cover that cannot be dismissed by swipe appears.

Four pages, with **"Next"** on pages 1–3, **"Continue"** on page 4, and **"Skip"** on every page:

1. **"Keep each belonging in a stall"** — **"Scan a barcode or QR into the open stall. You will know where it sits and who last received it."**
2. **"Scan seats. Scan hops."** — **"An unknown code writes a Tag here. The same Tag in another stall hops it, with a trail."**
3. **"Lent, overdue, freeze"** — **"Lent writes who received it. Issued longer than 30 days ranks on Lifecycle. Relinquish freezes that Tag."**
4. **"QR stays on this device"** — **"QR is the code if you have one, otherwise the id. Search stays on this device."**

**"Continue"** or **"Skip"** finishes onboarding. If there are no stalls yet, three are created: **"Bench"** (duty **"In stall"**), **"Crew hold"** (**"Lent"**), **"Repair pane"** (**"Repair"**). The main shell then shows the segmented control **"Inventory"** / **"Lifecycle"** / **"Settings"**. Onboarding can be shown again from Settings via **"Re-run onboarding"**.

## Screens

### Main chrome
Segmented control accessibility label **"Crib"** with segments **"Inventory"**, **"Lifecycle"**, **"Settings"**. No tab bar. Dark appearance throughout.

### Inventory
Header: medium-style date (device locale); hop count plus **"Hops"** (opens **"Stall then hop"**); large title is the open stall name, or **"Open a stall"**; subline **"Scan a barcode or QR to seat in {stall}. Hop a known Tag in from another stall."** or **"Add a stall in Settings, then scan."**

Stall chips (each stall name; selected = open). QR control **"Show stall QR"** (disabled with no open stall) opens the QR cover for that stall.

Search field **"Search names and codes"**. Status chips **"All"**, **"In stall"**, **"Issued"**, **"Repair"**, **"Relinquished"** (group **"Tag status"**).

Tag rows show name (or code / **"Unnamed Tag"**), status and optional stall / assignee / code, optional **"{n} day overdue"** / **"{n} days overdue"**, and ink such as **"Seated in {stall}. Scan in another stall to hop."**, **"Last hop {from} to {to}, {who}."**, **"Focused. Next Scan seats a new Tag or hops this one."** Tapping a row focuses it.

**"Next scan"** block with seating/hopping guidance and hop-ready lines. **"Trail"** list, or empty **"No hops yet. Scan a known Tag into another stall to write the first trail."**

Filtered empty: **"Nothing in this duty."** or **"No Tag matches that search."** / **"Clear the filter, or scan into this stall."** Button **"Show all"**, **"Clear search"**, or **"Scan"**.

Dock: focused Tag strip with **"QR"**, **"Peel"** or **"Remove"**, **"Relinquish"** (disabled if already Relinquished). Primary **"Scan"** with detail **"Seat or hop into {stall}"** or **"Open a stall first"** (disabled until a stall is open).

Empty Inventory (no Tags, or no stalls): **"Scan your first Tag"**; **"Add a stall in Settings, then scan a barcode or QR."** → **"Open Settings"**, or with an open stall **"Unknown codes sit in {stall}. A known Tag from another stall hops here."** → **"Scan"**.

Fault: **"The crib could not be read"** / **"The last copy failed. Try again."** → **"Retry"**. Notices use **"OK"** (e.g. hop results, **"Restored from a backup copy."**). Keyboard **"Done"**.

Confirmations: **"Peel last hop"** — **"The Tag returns to the stall it left."** / **"Keep"**; **"Remove Tag"** — **"This Tag has no hops. Removing it clears the seat."** / **"Keep"**; **"Freeze this Tag?"** — **"Relinquish"** / **"Keep"** — **"New hops on this Tag stop. Other scans still seat."**

### Scan (cover)
Title **"Scan into {stall}"** or **"Scan into this stall"**; close **"Close"**. Field **"Received by, if Lent"**.

Before camera permission: **"Read a barcode or QR"** / **"Stallage uses the camera to seat a Tag in the open stall, or hop one in from another stall."** → **"Continue"** (then the system camera dialog).

Denied: **"Camera is off"** / **"Stallage reads a barcode or QR to seat a Tag. Open Settings if you want the camera, or type a code below."** → **"Open Settings"** plus type field.

No camera: **"No camera on this device. Use a sample code or type one."** with **"Sample codes"** chips (stall **"Open {name}"**, Tag names, or samples such as **"XLR loom"**, **"Body 5D"**, **"Clamp light"**).

Live: **"Hold a barcode or QR in the frame. An unknown code seats. A known Tag from another stall hops."** Field **"Type or paste a code"** → **"Seat or hop"** (disabled when empty).

Notices include **"This Tag already sits in the open stall."**, **"This Tag is relinquished. Hops stay frozen."**, **"Open stall is {name}. Scan a Tag to hop it here."**, **"{Tag} hopped to {stall}, with {who}."**, **"Hop written."** Scanning a stall code opens that stall. A new seat that needs a name opens **"Name this Tag"**.

### Name this Tag (cover)
**"Name this Tag"** — **"It is seated in {stall}. Give it a name you will recognise."** Field **"Tag name"** → **"Continue"** (needs a non-empty name) or **"Later"**. Close dismisses without naming.

### QR (cover)
Title is the Tag or stall name (fallback **"QR"**). Shows the code payload and a QR image, or **"QR could not be drawn."** **"Share QR"**; **"Close"**.

### Stall then hop (cover)
**"Stall then hop"**. Empty: **"Seat here. Hop there."** / **"An unknown code writes a Tag into the open stall. Scan that Tag in another stall to hop it."** → **"Open Inventory"**. Populated: hop count; **"A new scan writes a Tag into the open stall. A known scan into another stall writes a Hop and a TrailMark. Relinquished freezes hops on that Tag."**; **"Trail {n}. Overdue {n}."**; hop rows; **"Open Inventory"**. Fault: **"The trail could not be read"** → **"Retry"**.

### Lifecycle
Title **"Lifecycle"**. **"{n}"** + **"hops in this crib. Overdue issued: {n}."** Sections **"Overdue"**, **"Hops"**, **"Trail"**, then **"Next hop"** (when an overdue Tag is selected) or **"Hop trail"**, then **"Seated now"**.

Overdue rows: **"Issued to {who}. {stall}."** and figure **"day overdue"** / **"days overdue"**. Tapping an overdue Tag fills **"Next hop"** with story lines and **"Scan"** (detail **"Hop {Tag} into {stall}"** or **"Open a stall, then hop {Tag}"**).

Empty: **"No hops yet"** / **"Hop a Tag into another stall to write a trail. Issued longer than 30 days will rank here."** → **"Open Inventory"**. Fault: **"Lifecycle could not be read"** → **"Retry"**. Per-stall empties: **"No Tags seated. Scan into this stall to seat one."** / **"No trail in {stall} yet. Hop a Tag here to write one."**

### Settings
Title **"Settings"**; section **"Stalls"**. Each stall: name, duty (**"In stall"** / **"Lent"** / **"Repair"** / **"Relinquished"**), Tag summary (**"No Tags yet. Scan to seat the first."** or names + **"Scan to seat or hop."**). Rename (pencil) → **"Rename stall"** / **"Stall name"** / **"Save"** / **"Keep"**. Stall QR. **"Scan seats or hops"** explanation and hop/overdue counts.

**"Add a stall"** (inline or sheet **"Add a stall"**): **"Stall name"**, duty picker **"Duty"** (same four labels), **"Save stall"**, caption **"Duty copies onto a new Tag when you scan it into this stall."** **"Stall then hop"** / **"How a scan seats or hops"**. **"Contact"** with support address shown under it (opens the support page). **"Re-run onboarding"**. **"Reset all data"** / **"Erase stalls and Tags on this device"** → **"Erase the crib?"** / **"Erase every stall, Tag, and hop"** / **"Keep"** / **"This clears stalls, Tags, hops, and trail on this device."**

Empty Settings: **"No stalls on this device"** / **"Add a stall, then scan a Tag into it. Contact stays here."** → **"Add a stall"** (Contact still shown). Fault: **"Settings could not be read"** → **"Retry"**.

## Features
- Crib of named stalls with one open stall at a time
- Tags seated by scanning unknown barcodes or QR codes (or typing a code)
- Hops: scanning a known Tag into another stall writes a hop and trail
- Duties and statuses: **"In stall"**, **"Lent"** / **"Issued"**, **"Repair"**, **"Relinquished"**
- **"Received by, if Lent"** on scan; hops record who received the Tag
- Overdue ranking on Lifecycle for Issued longer than 30 days
- Focus a Tag; **"Peel"** last hop or **"Remove"**; **"Relinquish"** freezes hops
- Local search of names and codes; status filters
- On-device QR for Tags and stalls; **"Share QR"**
- Stall then hop trail overview
- Onboarding with **"Skip"** / **"Next"** / **"Continue"**; re-run from Settings
- Reset all data on this device; Contact support link

## Behaviours that can look like bugs
- **"Scan"** stays disabled with **"Open a stall first"** until a stall chip is selected (or a stall exists and is open).
- Stall QR is disabled until a stall is open.
- **"Seat or hop"**, **"Save stall"**, and name **"Continue"** stay disabled while their fields are empty.
- **"Relinquish"** is disabled on a Tag already **"Relinquished"**.
- After onboarding with stalls but no Tags, Inventory shows **"Scan your first Tag"** until the first seat.
- Lifecycle shows **"No hops yet"** until the first hop or trail (or overdue Issued Tag).
- Filtered empty **"Scan"** does nothing if no stall is open.
- Camera denied still allows typing a code; **"Open Settings"** only opens system Settings.
- Duplicate identical scans within about two seconds are ignored.
- Capture pauses when the app backgrounds.
- Duty picker includes **"Relinquished"** for new stalls, so new Tags seated there can start frozen for hops.
- Scanning a Tag already in the open stall only focuses it and shows **"This Tag already sits in the open stall."**
- Relinquished Tag scan shows **"This Tag is relinquished. Hops stay frozen."** without hopping.
- **"Later"** on **"Name this Tag"** leaves the Tag as code / **"Unnamed Tag"** until renamed later by scanning flow again is not offered; name is optional via Later.
- Empty **"Received by, if Lent"** still hops; the receiver defaults to the destination stall name.
- System notification permission may appear at launch with no in-app explanation screen.

## Starter content and resume
After **"Continue"** or **"Skip"** with an empty crib: stalls **"Bench"**, **"Crew hold"**, **"Repair pane"**; no Tags.

On Simulator only, first empty run may seed demo stalls **"Bench"**, **"Crew hold"**, **"Repair pane"**, **"Relic shelf"** and Tags **"Body 5D"**, **"Clamp light"**, **"Bodice pin"**, **"XLR loom"**, **"Gel sleeve"**, **"Tape brick"**, with receivers such as **"Maya"** and **"Jonah"**, plus hops/trail and possible overdue.

Crib and onboarding completion are restored on relaunch. Unfinished Tag naming can be left via **"Later"**; stalls and Tags persist until reset. Possible banner **"Restored from a backup copy."** Unreadable crib → fault + **"Retry"**. **"Reset all data"** clears the local crib and returns to Inventory empty path. **"Re-run onboarding"** does not erase data by itself.

## Permissions
- **Camera** — asked the first time Scan reaches the pre-permission screen and the user taps **"Continue"**. System usage string: **"Stallage uses the camera to read a barcode or QR on a tagged tool, cable, camera, or costume so it can be seated in a stall."** If denied: in-app **"Camera is off"**… and **"Open Settings"**.
- **Notifications** — system permission prompt near cold launch; no custom in-app copy.
- Photos, microphone, location, tracking: none.

## Absent
Login or accounts; in-app purchase; ads; analytics consent UI; public or shared user-generated content feed; account deletion flow; App Tracking Transparency prompt. (Users do name Tags and stalls privately on this device.)

## Data and support
Copy and reset emphasize data **"on this device"**; search and QR stay on this device. Inventory, stalls, Tags, hops, and trail live locally. Settings **"Contact"** shows **"https://stallage-crib.pro/contact-us"** underlined under the label; tapping opens the support page.

## Scanning and health
Scans barcodes and QR codes (camera or typed/pasted code). Unknown code seats a Tag in the open stall; known Tag in another stall hops; stall QR opens that stall. Sample codes on devices without a camera. No health, medical, fitness, or product-nutrition information. Citations: None.

## Platform
No region lock; UI English only; dates follow the device locale. Portrait only on iPhone and iPad; requires full screen; dark appearance. Minimum iOS 17.0.

## Category
Productivity

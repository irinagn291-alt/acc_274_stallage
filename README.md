# Stallage

Stallage is for people who label tools, cables, cameras, or costumes and need to know which stall holds each belonging and who last received it. A keeper scans a barcode or QR into the open stall. An unknown code writes a Tag. Scanning that Tag in another stall hops it.

## Architecture

Seat-hop encoding. `CribStore` is the only persistence seam. A new scan on the open stall writes a `Tag` and a `Seat`, and copies that stall’s Duty onto status. A known Tag scanned onto a different stall writes a `Hop`, a `TrailMark`, `assignedTo`, and moves the Seat. Lent copies issued onto status. Relinquished freezes hops on that Tag. Issued longer than 30 local days ranks overdue on Lifecycle.

This pattern fits the product because the same scan is the verb. The crib never leaves. Inventory, Lifecycle, and Settings are segments on one screen. There is no transfer form and no remote catalog.

## Stall then hop

Home is the open stall. Scan seats or hops:

1. Unknown code writes a Tag into the open stall and fuses a name in place.
2. Known code from another stall writes a Hop and a TrailMark, then moves the Tag.
3. Relinquish freezes hops on that Tag. New scans still seat other Tags.
4. Undo peels the last Hop, or the Tag if it has none.

QR is the code if present, otherwise the id. Search filters Tag name and code in memory.

## Look

Lavender calm journal. SF Pro. Quiet motion, 180 ms cross-fade. Hairline stall rail, ink lines, filled-capsule Scan. Glass renders are cutout brand art, not a frosted UI.

Art style: 3D glass render, glassmorphism. Base prompt reused for every asset:

```
3D glass render, glassmorphism, frosted translucent stall crib, quiet journal still life, tagged tools cables cameras and costume tags seated in glass stalls, soft studio light, refraction, no text, no captions, no letters, no emoji, no UI chrome
```

Exact prompts per image set (generated in a later assets step):

- `slg_AppIcon` — A single glass crib stall filling the square canvas, 3D glass render, one tagged tool silhouette hanging inside a frosted pane, subject in the center 80 percent, no text, no letters, no rounded-corner mask, no drop shadow leaving the canvas, opaque, no alpha
- `slg_Splash` — Tall quiet glass crib, frosted stalls receding, uncluttered centre band for a wordmark, 3D glass render, no text in the image, no letters
- `slg_Onboarding1` — Cutout of a keeper holding a tagged cable beside a small glass stall, isolated on transparent ground, 3D glass, all four corners transparent, no square plate
- `slg_Onboarding2` — Cutout of a barcode tag being seated into an open glass stall mouth, mid-gesture, isolated, transparent corners, no plate, no text
- `slg_Onboarding3` — Cutout of two glass stalls with one tagged belonging hopping between them, isolated, transparent corners, no plate, no text
- `slg_EmptyHome` — Cutout of an empty open glass stall waiting, quiet, inviting, isolated on transparent ground, all four corners transparent, no plate
- `slg_EmptyList` — Cutout of a blank journal leaf with a faint empty trail, isolated, transparent corners, no plate, no text
- `slg_CardBackdrop` — Soft abstract glass stall panes filling the canvas, low contrast, no text, no letters, suitable behind ink
- `slg_ControlFace` — Cutout face of a filled-capsule scan control as a small glass stall mouth, isolated, transparent corners, no plate, no text
- `slg_TwistHero` — Cutout emblem of a tagged belonging hopping from one glass stall to another, isolated, transparent corners, no plate, no text
- `slg_SuccessMark` — Cutout of a small glass check seated in a stall mouth, isolated, transparent corners, no plate, no text
- `slg_HeaderDecor` — Wide quiet glass hairline rail ornament, journal date-rail feel, low contrast, no text, no letters

## How this differs

Home is a crib of stalls where the same scan either seats or hops, not an asset list with a transfer form. There is no product timeline, no Open Food Facts, no grams or best-before rail, and no cocktail bar. cgi search.pl stays dark. Contact is a Settings link to https://stallage-crib.pro/contact-us, not a product WebView.

## Build

```bash
cd Stallage
xcodegen generate
xcodebuild -scheme Stallage -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcodebuild build-for-testing -scheme Stallage -destination 'generic/platform=iOS Simulator'
```

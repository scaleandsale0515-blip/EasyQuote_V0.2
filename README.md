# EasyQuote

Native Flutter Android app for quotation & invoice management — built for
precast concrete factory clients. Fully offline; every device keeps its own
independent data (no cloud, no account sync).

## Features

**Security**
- Admin lock on first launch (Admin ID + Password). Only a salted SHA-256
  hash of each is stored in the compiled app — never the real values in
  plain text. Wrong credentials never unlock the app (no bypass). Uninstall
  + reinstall wipes local storage, so it asks again.

**Local-only storage**
- All data — company profile, clients, catalog items, terms presets,
  quotations, invoices — is stored on-device using Hive (`hive_ce` /
  `hive_ce_flutter`, the actively-maintained fork; the original
  `hive`/`hive_flutter` packages are abandoned).
- Images (logo, signature, stamp) are copied into the app's private
  documents folder.
- Nothing syncs automatically between devices. A **Backup & Restore**
  screen lets you manually export a JSON file from one device and import
  it on another, on purpose.

**Company Profile**
- Company details, contact info, branding (logo/signature/stamp upload),
  GSTIN/jurisdiction/default GST%/Ref. No. prefix, bank details.

**Clients, Items Catalog, Terms Templates**
- Full CRUD screens for reusable clients, catalog items (description/unit/
  rate/grade), and Terms & Conditions presets (the 5-clause structure from
  the original template: Payment, Transport/Liability, Delivery/Claims,
  Validity, Jurisdiction).

**Quotation / Invoice builder**
- Client picker (with inline "add new client"), date/due date, line items
  (manual or pulled from the catalog), header notes, spec/italic notes,
  GST%, PO clause, terms preset selection (a **snapshot** of the preset's
  wording is saved with the document, so editing a preset later doesn't
  change wording on documents already issued), status tracking (Draft,
  Sent, Accepted, Paid, etc.), and for invoices: amount paid / balance due.

**Real PDF export — not an image**
- Built with the `pdf` + `printing` packages: actual vector text (selectable,
  searchable, copyable), not a screenshot.
- Layout fixes from the original web template, addressed directly in
  `lib/pdf/pdf_builder.dart`:
  - **Terms & Conditions always starts on a fresh page** — forced with
    `pw.NewPage()`, not CSS, so it's guaranteed regardless of content length.
  - **Proper page margins** (~17mm on all sides) so content never touches
    the paper edge.
  - **Date/Ref. No. box is a narrow fixed width**; the To/Kind Attn/Mo/Email
    block gets the larger share of the row.
  - **Totals (Subtotal/GST/Total) are right-aligned**, not centered.
- Preview screen uses `printing`'s `PdfPreview` widget — built-in
  Print / Share / Save buttons, no extra wiring needed.

**Dashboard**
- Quotation/invoice counts and totals, amount paid vs outstanding, and a
  6-month invoice total bar chart.

## About the included `android/` folder

This is a complete, hand-written Android platform folder (Gradle files,
manifest, launcher icons, etc.) — not auto-generated. Versions used:

- Android Gradle Plugin 8.7.0
- Kotlin 2.1.0
- Gradle 8.10.2 (current stable, compatible with the above)
- `minSdk` 21, `compileSdk`/`targetSdk` follow whatever Flutter itself
  recommends at build time (`flutter.compileSdkVersion` / `flutter.
  targetSdkVersion` — these stay current automatically since they're
  pulled from the Flutter SDK Codemagic installs, not hardcoded here)

**One honest trade-off to know about:** unlike `flutter.compileSdkVersion`
above, the Gradle/AGP/Kotlin versions *are* hardcoded numbers in this
folder. Android tooling moves fast — at some point in the future Flutter
may warn that these are outdated and ask for an upgrade. If/when that
happens, just tell me the version numbers Flutter suggests and I'll update
`android/settings.gradle.kts` and `android/gradle/wrapper/gradle-wrapper.properties`
accordingly — that's the entire fix, just those two files.

The launcher icon PNGs in `android/app/src/main/res/mipmap-*/` are
included directly (generated from your icon image), and `codemagic.yaml`
also re-runs `flutter_launcher_icons` on every build to regenerate them
(including a proper adaptive icon) — so the icon stays correct even if
you swap `assets/icon/app_icon.png` for a new image later.

`android/app/src/main/AndroidManifest.xml` already has the app label set
to "EasyQuote" and the permissions needed for picking logo/signature/stamp
images from the gallery and sharing generated PDFs.

## How to build

1. Push this whole folder to your GitHub repo (same flow as FactoryFlow).
2. In Codemagic, add this repo as a new app — it auto-detects `codemagic.yaml`.
3. Start a build on the `easyquote-android` workflow.
4. Download the `.apk` from the build artifacts.

## Admin credentials

- ID: `FactoryFlowRP2026`
- Password: `AdxyRBP@7989Qwop`

Only a salted SHA-256 hash of each lives in `lib/auth/admin_auth.dart` — not
the plain text. If you ever want to change either value, just tell me the
new ones and I'll regenerate the hashes.

## What's intentionally not included (future ideas, not built)

- Multi-user / role-based access (this is a single-admin-lock app, by design)
- Automatic cloud sync (deliberately excluded — see "Local-only storage" above)
- PDF e-signature capture (currently: upload a signature/stamp image, or a
  text fallback)

## Update — this round

- **Dashboard**: chart tooltip text now white; heading shortened to "INVOICE TOTAL"; added Day/Week/Month filter chips; added an Overdue Invoices card (tap to see the filtered list); added a 30-day backup reminder banner.
- **Paid/Outstanding stats**: now correctly reflect Paid and Partially Paid status even if "Amount Paid" wasn't separately typed in. Status and Amount Paid sync both ways on the invoice form.
- **Terms Templates**: reworked from a fixed 5-field schema into a free-form clause list (add as many or as few as needed). A brand-new preset now starts genuinely blank — it no longer gets pre-filled with old default wording. One ready-made "Standard Precast Terms" preset is seeded for convenience. Old saved presets are migrated automatically.
- **Include Terms & Conditions toggle**: added to the document form — turn off entirely when a document doesn't need a Terms page. Bank Details/Signature still show either way.
- **Quotation → Invoice (one tap)** and **Duplicate document**: available from both the documents list (⋮ menu) and the preview screen (icon buttons).
- **Search + filters** on Quotations/Invoices screens: search by Ref. No./client, status filter chips (including Paid/Partially Paid/Overdue for invoices), date range quick filters + custom range picker.
- **Multiple Company Profiles**: Company Profile is now a list — add/edit/delete several, mark one Active. Each document remembers which profile issued it.
- **In-app Terms & Conditions page** (More menu) — formal legal text for Play Store compliance. **Edit the bracketed placeholders before publishing**, and note Play Store also requires a separately hosted Privacy Policy URL, which isn't part of this in-app screen.

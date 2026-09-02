---
name: syndic8-import-export
description: |
  Understand and troubleshoot Syndic8 data imports and exports — import flows (dataflows), required inbound mappings, SkipEmpty, upload order, import history, verifying a load actually landed, export runs, and Third-Party Messages. Use whenever the user mentions importing data, import flows, import configuration, upload files, import history, exports, syndication runs, or "my data didn't load / didn't export".
---

# Syndic8 Import & Export

How data gets in and out of Syndic8. Imports are created and run in the app (Import screen wizards, with the in-app copilot's help) — this skill is the model you need to plan them, name them, verify them, and diagnose them.

## Import concepts

Data enters through **import flows** (dataflows). Each flow binds an inbound mapping template (source columns → Syndic8 fields) to a file shape, and accepts XLSX/XLSM/XLS, CSV, TXT, JSON, or XML. Processing is **asynchronous** — status appears in Import History (`/org/{orgId}/import-history`) and may lag the upload.

**Imports upsert by UPC** — re-loading a corrected file updates existing products rather than duplicating them. (Image import flows are the exception: they insert, never upsert — see `syndic8-media`.)

### ★ Name flows carefully — names are permanent

The Import Flows screen shows the flow's name, the name **cannot be changed later**, and it's what everyone in your org sees. Decide final, human-readable names before creating flows (e.g. `Products`, `Pricing`, `Media`, `Marketing Copy`), one flow per file type. A misnamed flow must be recreated.

### Required inbound mappings (product imports)

A product import missing these produces incomplete products:
- **Product Type** — mapped to the platform taxonomy via a valid-value/convert rule (see `syndic8-pim`)
- **Product Name**, **SKU**, and **UPC** (the unique key imports upsert on)
- **Style number** — drives size rollup and image matching
- **MSRP + ISO currency code**, **Company/Brand Name** (brand attribution happens at import)
- Collection membership, if driven from the file (`Create Collection Name`, comma-separated)

### SkipEmpty

`skipEmpty` defaults **TRUE**: a blank inbound cell never overwrites a saved value (and a mapping's default only fires on blank cells). Leave it TRUE; set FALSE only for a deliberate clean-slate reload, then set it back.

## Loading well

1. **Order**: product attributes → pricing → marketing → images.
2. **Start small**: a 1-row test load first, then the full file.
3. **Verify values, not just status.** A `Complete / 0 failed` run can still have silently skipped columns the mapping didn't cover. After a load, spot-check every column you care about with `queryProducts` — if a populated source column didn't land, the mapping needs that column added.
4. **After replacing/reloading products**: pricing, separately-uploaded media, and manually-built collection memberships do **not** automatically follow — re-load pricing, re-check media matching, and re-verify collection counts.

## Exports

An export selects products through a collection/sub-catalog connected to the destination, transforms each field through the channel template, and delivers the file via the configured connection (SFTP, marketplace API, download).

- ⚠️ **A "Complete" export of nothing is a real failure mode** — if the product selection was empty you get a successful run with a header-only file and no error. Check the run's product count and open the file.
- The exported **file is the proof**: row count matches, transforms applied, no blank columns.

## Third-Party Messages (Admin → Third-Party Messages)

The delivery log for marketplace API sends:
- **2xx** = accepted by the retailer · **4xx** = likely a payload/config problem on the Syndic8 side · **5xx** = the retailer API's problem.
- Amazon can take up to ~24h to reflect a delivered feed — no visible change isn't immediately a failure.

## Where to do what

- **Create/modify an import flow**: the app's Import screen wizards (the in-app copilot assists). Verify afterward — check the flow exists and run a test load; a chat message saying it was created is not the verification.
- **Re-run an existing flow with a corrected file**: upload with the same filename, re-trigger from the app.
- **Query what a load produced**: MCP — `queryProducts`, `queryProductAggregate`, `queryPricing`, `queryProductMedia`.

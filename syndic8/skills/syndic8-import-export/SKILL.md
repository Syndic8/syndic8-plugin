---
name: syndic8-import-export
description: |
  Understand and troubleshoot Syndic8 data imports and exports — import flows (dataflows), the two wizard modes, required inbound mappings, SkipEmpty, pricing loads, deletion flows, import-driven collections, upload order, import history, verifying a load actually landed, re-running imports, export runs, and Third-Party Messages. Use whenever the user mentions importing data, import flows, import configuration, upload files, pricing loads, deleting products by file, import history, exports, syndication runs, or "my data didn't load / didn't export".
---

# Syndic8 Import & Export

How data gets in and out of Syndic8. Imports are created and run in the app (Import screen wizards, with the in-app copilot's help) — this skill is the model you need to plan them, name them, verify them, and diagnose them. Querying what a load produced is MCP work (`queryProducts`, `queryPricing`, `queryProductMedia`, `queryCollectionProducts`).

## Import concepts

Data enters through **import flows** (dataflows). Each flow binds an inbound mapping template (source columns → Syndic8 fields) to a file shape, and accepts XLSX/XLSM/XLS, CSV, TXT, JSON, or XML. Processing is **asynchronous and queued** — status appears in Import History (`/org/{orgId}/import-history`, the "Product Content Imports" screen) and may lag the upload by a few minutes. A run that sits at "Pending" for a long time is a platform-side queue question, not a file problem — raise it with support rather than re-uploading.

**Imports upsert by UPC** — re-loading a corrected file updates existing products rather than duplicating them. (Image import flows are the exception: they insert, never upsert — see `syndic8-media`.)

**Everything real loads through an import.** Products created directly through the API display their create-body fields but are never "completed" by the pipeline that runs on import — field edits and media matching don't take on them. Use direct creation only for a throwaway test; load the catalog through a flow.

**Import templates belong to one org.** An inbound template is bound to the org it was created in — create each org's import templates natively in that org through the wizard rather than reusing another org's.

### ★ Name flows carefully — names are permanent

The Import Flows screen shows the flow's name, the name **cannot be changed later**, and it's what everyone in your org sees. Decide final, human-readable names before creating flows (e.g. `Products`, `Pricing`, `Media`, `Enriched Content`), one flow per file type. A misnamed flow must be recreated and the old one removed.

**Enumerate the full flow set up front.** A complete org typically needs 4–6 flows for product data (Products, Pricing, Media, marketing/enriched copy), plus customer, pricing and inventory flows where B2B commerce is enabled. **Prove one flow first** — create it, see it on the Import Flows screen, run a 1-row load — then create the rest.

### The two wizard modes

| Mode | Use when | Watch for |
|---|---|---|
| **Create with AI** | A brand-new inbound template for a new file shape | Mints a new, very wide auto-matched template; low-confidence mis-routes are normal — especially **value-vs-unit column pairs** (a "Package Weight Unit" column landing in the weight field, a "Carton Height Value" column landing in an unrelated unit field). Budget a full readback pass (below). |
| **Create manually** | A lean inbound template **already exists** and just needs a flow bound to it | Using "Create with AI" here mints a duplicate template instead of binding the existing one. |

The copilot's "Import config created successfully" message is a chat message, not evidence. Confirm on the Import Flows screen that the flow exists, then run a test load.

### Required inbound mappings (product imports)

A product import missing these produces incomplete products:
- **Product Type** — mapped to the platform taxonomy via a valid-value/convert rule (see `syndic8-pim`)
- **Product Name**, **SKU**, and **UPC** (the unique key imports upsert on)
- **Style number** — drives the style roll-up, size grouping, and image matching; where a partner feed carries its own variant/parent id, map it to `OriginalProductId` as well
- **MSRP + ISO currency code**, **Company/Brand Name** (brand attribution happens at import)
- Collection membership, if driven from the file (`Create Collection Name`, comma-separated — see below)
- Any valid-value (controlled vocabulary) fields your channels require

### SkipEmpty

`skipEmpty` defaults **TRUE**: a blank inbound cell never overwrites a saved value (and a mapping's default only fires on blank cells). Leave it TRUE; set FALSE only for a deliberate clean-slate reload, then set it back.

### Import-driven collection management

- **Product-level**: a `Create Collection Name` column (comma-separated list per row) adds each product to those collections, creating them if needed. Paired with **`Remove Missing Collections`** (default true), a product is also removed from any collection *not* listed on its row — so a partial file with this flag on can silently empty collections. Collections and trading-partner sub-catalogs are treated identically by this mechanism.
- **File-level**: dedicated `Sub Catalog` and `Catalog Product Map` import types build a whole collection's membership from a file.
- Collections built by hand (or by MCP `addCollectionProducts`) are **not** touched by imports unless the file names them.

## ★ The mapping gate and the post-import readback

**Before running:** open the flow's template and check that every required field is mapped to a real source column (a required field with no column mapped means a blank product attribute, not a failed row). Use **display-name headers** in your workbook (`Shoe Height`, not `SHOE_HEIGHT`) — internal-name headers auto-match far worse. Then a **1-row test load** before the full file.

**After running: `Complete / 0 failed` says nothing about dropped columns.** An auto-mapped template can wire a fraction of the file and silently omit populated, valid columns; a completed run can also drop a mapped column with no error anywhere. So:
1. Compare **every populated source column** against `queryProducts` on the loaded rows — not a spot-check. `describeProductFields` tells you the internal name a column should have landed in; `diagnoseField` explains why a field is empty or unavailable.
2. Repair by adding the missing mapping in the template, re-run, re-read.
3. **Extend mappings one at a time.** Adding many mappings in one pass can turn the next run into an all-rows failure with no row errors surfaced; add one, run, confirm, then the next.

## Pricing loads

Pricing is its own data domain and loads through a **Pricing** import flow (not the product flow). A pricing file carries the product key plus price rows:
- **Matching**: rows match existing products on **SKU or UPC** — load products first, or pricing has nothing to attach to. Pricing rows are keyed to the product record, so **after any product reload or replacement, re-load pricing** — it does not follow the rebuild.
- **Price types**: MSRP, MAP, and wholesale cost, each with an **ISO currency code** (`USD`, `GBP`, …). Multiple same-type prices in one currency use a synthetic code (e.g. `GBP_WHOLESALE_EU`, up to 32 characters) and a template convert selects the right one at export.
- **Trading-partner price overrides** are pricing rows scoped to a destination; at export the override wins over the core price (see `syndic8-trading-partners`).
- Up to two **future prices** with effective dates can be stored per price type — they are storage, not scheduling: the platform does not switch prices on the effective date.
- Verify with `queryPricing` / `queryPricingAggregate` (`describePricingFields` for the field names), not with the import status alone.

## Deletion flows

- **Item deletion** is its own import flow, not a flag on the product flow: a file of keys plus an `IsDeleted` indicator, mapped to the flow's **Delete Record** field. Keep the deletion flow separate and named for what it does (`Delete Products`) so no one runs it by accident.
- For a handful of products, MCP `deactivateProducts` is simpler and reversible; use a deletion flow for bulk, file-driven removals.
- Image deletion is handled in Media Management, not by product flows — see `syndic8-media`.

## Re-running an import

Once a flow exists, re-running needs no wizard: on the Import screen pick the flow, upload the corrected file **with the same filename** (same-name uploads overwrite in place), and trigger. Product imports upsert by UPC, so a re-run is the normal fix for a bad column; an image-flow re-run duplicates media rows (see `syndic8-media`).

## Loading well

1. **Order**: product attributes → pricing → marketing copy → images.
2. **Start small**: a 1-row test load first, then the full file. Pipe-delimited CSV if your data contains commas.
3. **Verify values, not just status** (the readback above).
4. **After replacing/reloading products**: pricing, separately-uploaded media, and manually-built collection memberships do **not** automatically follow — re-load pricing, re-run media matching, re-check every static collection and trading-partner sub-catalog count. Smart collections re-evaluate on their own; anything keyed on the product record does not.

## Validation — three places, every time

1. **Run status** on the Import screen / Import History — `Complete`, counts, failures.
2. **Import History detail** — the row-level errors; this is the only place row errors appear.
3. **Query the data** — `queryProducts` / `queryPricing` / `queryProductMedia` / `queryCollectionProducts` against the columns you loaded. A load is done when the data reads back, not when the status says Complete.

## Exports

An export selects products through a collection/sub-catalog connected to the destination, transforms each field through the channel template, and delivers the file via the configured connection (SFTP, marketplace API, download). Export runs appear per destination on the Trading Partners screen.

- ⚠️ **A "Complete" export of nothing is a real failure mode** — a trading-partner sub-catalog is a static product set, and after a product reload the selection can be empty: a successful run, a header-only file, no error. Check the run's product count and open the file.
- The exported **file is the proof**: row count matches, transforms applied, no blank columns. `runPreflight` scoped to the collection + destination before exporting tells you what the file will be missing.

## Third-Party Messages (Admin → Third-Party Messages)

The delivery log for marketplace API sends:
- **2xx** = accepted by the retailer · **4xx** = likely a payload/config problem on the Syndic8 side · **5xx** = the retailer API's problem.
- Amazon can take up to ~24h to reflect a delivered feed — no visible change isn't immediately a failure.
- Retailer sandboxes are rare, so connection testing usually runs against the live channel: use delisted or zero-inventory test SKUs and guard prices.

## Practices that save a re-load

- Import errors can lag the status — refresh Import History before concluding a run had none.
- A client-feed load with a wrong-shaped row can report Complete with `pass 0 / fail 1` and no row error — the 1-row test load is what catches shape problems.
- Never bulk-extend a template's mappings; never re-run an image flow without planning the dedupe; never run a file with `Remove Missing Collections` on unless it carries every product's full collection list.

## Where to do what

- **Create/modify an import flow**: the app's Import screen wizards (the in-app copilot assists). Verify afterward on the Import Flows screen and with a test load.
- **Re-run an existing flow with a corrected file**: same filename, re-trigger from the app.
- **Query what a load produced**: MCP — `queryProducts`, `queryProductAggregate`, `queryPricing`, `queryProductMedia`, `queryCollectionProducts`.
- **Collections**: MCP `createCollection` / `addCollectionProducts` / `removeCollectionProducts` for hand-built membership; the import file for file-driven membership.

## Advanced: controlled API reads

There is no dedicated MCP tool for listing flows or import history, so `callApiRead` fills the gap — reads only:
- Import flows: GET `org/{orgId}/dataflow` (a flow's `dataFlowName` is the permanent screen name; `fileInputUrl` is the file it reads).
- Import history: GET `org/{orgId}/import/product` and GET `org/{orgId}/import/image`; a single run at `.../import/product/{productImportId}`.
Rules: the path must include the org segment, query parameters (e.g. `limit`, `offset`) go in `query` not the path, and no whitespace in paths. ⚠️ `org/{orgId}/dataflow/{dataFlowId}/import` **starts an import** even though it is a GET — never call it to "read" a flow. Prefer the app for any change; `callApiWrite` has no place in import operations.

## Related

- Product model, taxonomy, and collections: `syndic8-pim`.
- Media loads, matching, and image-import behaviour: `syndic8-media`.
- Destinations, connections, and per-destination overrides: `syndic8-trading-partners`.
- Auditing what the import produced: `syndic8-data-audit`.

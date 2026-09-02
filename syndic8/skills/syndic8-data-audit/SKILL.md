---
name: syndic8-data-audit
description: |
  Run and interpret Syndic8 data quality checks — the Data Audit and Verification screens, diagnosing bad audit scores (wrong or too-high-level product category), reading preflight results correctly, metadata matrices, and reference tables. Use whenever the user mentions data audit, audit score, data quality, field completeness, verification, preflight results, required fields failing, metadata matrices, or reference tables.
---

# Syndic8 Data Audit & Verification

How to audit product data quality and — more importantly — how to diagnose a *bad-looking* audit, which is usually a category problem rather than a data problem.

## The screens

- **Data Audit** (`/org/{orgId}/data-audit`) — completeness of product data per field, per trading partner. Run after any significant load.
- **Verification** (`/org/{orgId}/verification`) — validation against trading-partner requirements.
- **Metadata Matrices** (`/org/{orgId}/metadata`) — the per-product-type field model: which fields a category carries, which are required/recommended, and valid-value mappings per trading partner. Query it via `queryMatrix`.
- **Reference Tables** (`/org/{orgId}/freight-forwarding/reference-table`) — lookup tables used by `FUNC:REFERENCETABLE` mapping rules at export.

## ★ Diagnosing a bad audit score — check the CATEGORY first

The audit scores each product against the matrix field model for the product's **own assigned category** (product type + subtype). The most common cause of a terrible score is products assigned to a **top-level category** instead of a granular one:

- Top-level categories are huge field supersets — a faucet audited at the top level gets scored on "batteries required" and dozens of other irrelevant required fields, and an otherwise-clean catalog can grade F.
- **The fix is the category assignment, not the data**: assign products to the granular retailer-synced category. Granular categories come into the org through channel template creation (picking the retailer's leaf category pulls its schema and syncs the matrix) — an implementation task; if the right category doesn't exist yet, raise it with your Syndic8 implementation contact.
- When a required-field failure list mixes obviously-irrelevant fields with genuinely missing ones, split it: irrelevant → category problem; genuinely absent → the column really is missing from your source data.

## Reading preflight correctly

- `runPreflight` is **collection-scoped** — scope it to a collection or the results are empty/unusable.
- Read the error **categories/summary**, not a sample row — a few clean-looking products say nothing about the run.
- Run preflights **one at a time**, not in parallel.
- Three buckets: required-missing (blocking), recommended (quality), invalid values (present but not channel-accepted). `diagnoseField` on any flagged field tells you whether the issue is the mapping, the requirement config, or source population — fix at that layer, then re-run.
- The final proof of channel readiness is a real **export file opened and inspected** — row count matches, transforms applied, no blank columns.

## Reference tables

`FUNC:REFERENCETABLE::TableName;returnField;param=$D{FIELD}` looks up a row at export and returns a column. Two cautions:
- **Name tables distinctively** (e.g. `{Channel} {Category} Category` rather than a generic name) — lookups resolve by name.
- **A lookup miss produces an empty cell with no warning** — a "successful" export can carry a blank column. Audit the exported file.

## The data-quality loop

1. Load data (imports — see `syndic8-import-export`)
2. Confirm category assignments are granular (above)
3. Data Audit → find gaps
4. Verification / preflight → validate against channel requirements
5. Fix gaps (import a correction file, or targeted updates via `previewBulkUpdate` → `bulkUpdateProducts`)
6. Re-audit, then export and inspect the file

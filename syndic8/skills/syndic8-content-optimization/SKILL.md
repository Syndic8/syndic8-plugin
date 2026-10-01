---
name: syndic8-content-optimization
description: |
  Optimize Syndic8 product content for a specific retail channel — score titles, descriptions, bullets, images, and attributes against the destination template's requirements, rewrite what falls short, fill attribute gaps with channel-accepted values, and write the result back safely. Use whenever the user wants to improve listings, get products "ready for" a retailer, raise content quality or readiness, fix title/description/bullet problems, fill missing required attributes, or prepare a collection before its first syndication to a trading partner.
---

# Syndic8 Content Optimization

How to take the product content already in Syndic8 and make it ready for a particular channel: find the destination's actual requirements, measure the current content against them, rewrite what needs it, and write back without damaging anything you were not asked to touch. The channel's rules come from the template and from Syndic8's channel guidelines — never from memory.

## When to use

- "Get these products ready for {retailer}" / "why are these failing for {retailer}?"
- Rewrite titles, descriptions, or bullets for a destination
- Find and fill required-but-missing attributes before a first syndication
- Raise content quality or discoverability on a marketplace listing
- A preflight run reports content problems (length, format, invalid values) rather than data-load problems

Not for: authoring the retailer rules themselves (that is Syndic8's channel-guideline content), loading a catalog (see `syndic8-import-export`), or diagnosing audit scores driven by category assignment (see `syndic8-data-audit`).

## Where the rules come from

**Do not hard-code retailer numbers.** Title lengths, bullet counts, image rules, and accepted values differ by channel, by category, and over time. Pull them live:

1. **The destination template** — `listTemplates` → `getTemplateOverview` → `listTemplateFields`. Field rows carry the required flag, max length, data type, and any default. This is the authoritative "what the file must contain".
2. **Valid values** — `getValidValueColumns` lists which template fields are constrained to a value set; `getBrandValidValueMatches` / `getBrandValidValueNotMatched` / `getBrandValidValueCounts` show which of your brand's current values already map to accepted values and which do not.
3. **Channel guidelines** — the in-app Syndic8 copilot and the channel-guideline tools (when available) hold the editorial rules: title formulas, tone, prohibited claims, image composition. Use them for the "how to write it" layer; use the template for the "what fits in the field" layer.
4. **Field mappings** — `getFieldMappings` tells you which product field feeds each channel column, so you edit the field that is actually exported.

If a requirement is not in any of these, say so and ask rather than inventing one.

## Core workflow

### 1. Identify the destination and scope
Confirm the channel (and, if the template is category-specific, the category) and the product set — a collection is the right unit. Note which template the trading partner uses.

### 2. Pull the template's requirements
`listTemplateFields` for the template. Build a requirements sheet: field, required?, max length, valid-value set?, source product field (from `getFieldMappings`). Group it into title / description / bullets / images / attributes.

### 3. Pull the product data
`describeProductFields` first — field names are org-specific. Then `queryProducts` for the scoped products, requesting only the fields the requirements sheet names. `queryProductMedia` for image count, tags, and hero state. Use `queryProductAggregate` for "how many are missing X" questions before pulling records.

### 4. Score current content
Score each product against the sheet, not against a generic rubric. Report per product and in aggregate:

| Dimension | What you check |
|---|---|
| Title | present, within the template's max length, follows the channel's formula, no prohibited patterns |
| Description | present, within length bounds, structured, no prohibited claims |
| Bullets | count the template expects, each within its field's length, benefit-led |
| Images | count, hero present, composition matches channel guidance |
| Attributes | every required field populated; constrained fields hold an accepted value |

Lead with the blockers (required-missing, invalid values, over-length), then quality items. Note that this is a content assessment you compute — the platform may also attach its own scoring template to an export template; if the user says "the score", establish which one they mean.

### 5. Optimize
Draft the new values per product, then show them side-by-side with the current values before anything is written. Keep drafts inside the template's limits by construction — a title one character over the max is a failed row.

### 6. Write back — preview, confirm, apply
1. `previewBulkUpdate` with exactly the fields you drafted — show the user the change count and a sample.
2. Only after explicit confirmation, `bulkUpdateProducts`.
3. Re-run `runPreflight` on the same collection to prove the fix landed and did not introduce new failures. `diagnoseField` on anything still flagged.

## Example: "get the Spring collection ready for {retailer}"

1. `listTemplates` → pick the trading partner's template; `getTemplateOverview` to confirm it is the one the destination exports with.
2. `listTemplateFields` + `getFieldMappings` → requirements sheet (required, max length, valid-value set, source field).
3. `describeProductFields` → `queryProducts` on the collection for just those source fields; `queryProductMedia` for hero and image counts.
4. Score; report "ready / blocked / top failing fields". Ask the user which dimensions to fix.
5. Draft titles and bullets within the field limits; look up constrained attributes with `getBrandValidValueNotMatched` and propose accepted values.
6. `previewBulkUpdate` → user confirms → `bulkUpdateProducts` → `runPreflight` on the collection → report what moved from blocked to ready.

## Content principles (channel-agnostic)

Apply these as defaults; the channel's guideline and the template's limits override them.

**Titles** — brand, then the most specific product type, then one or two differentiators (size, colour, material, key feature). Sentence or title case, never all caps; no promotional words, no competitor names, no special characters unless the channel allows them. Check the channel's length limit — the template field's max is the hard cap.

**Descriptions** — lead with the primary benefit or use case; two or three short paragraphs; keywords used naturally, never stuffed; include compatibility, care, or warranty where relevant. Avoid claims the channel prohibits (medical, superlative, comparative).

**Bullets** — one idea per bullet, feature or benefit first, capitalised opener; cover key feature, dimensions, material, use case, what is included. Bullet count and per-bullet length come from the template's bullet fields.

**Images** — a single hero image per SKU (see `syndic8-media`), then lifestyle, detail, dimensional, and in-use shots. Background, framing, and resolution rules are channel-specific — check the channel guideline. No watermarks, borders, or text overlays unless the channel permits them.

**Attributes** — populate every required attribute before syndication; use the channel's accepted value exactly as the valid-value set spells it; never leave "Other" or "N/A" where a specific value exists.

## Know your source system

Where the content came from predicts what you will find. ERP-fed catalogs (NetSuite, SAP, Dynamics) have clean identifiers, dimensions, and pricing but warehouse-style names and little or no marketing copy — expect to write titles, descriptions, and bullets from scratch. DTC platforms (Shopify and similar) bring consumer-facing copy that is usually good but not shaped to retailer formulas or lengths, and prose rather than bullets. DAM-fed media is high quality but may carry licensing expiries and non-standard shot naming. Taxonomy almost never matches the retailer's regardless of source — plan for valid-value work every time.

## Working in batches

- Optimize in **small batches** (a collection, or a few dozen products) and re-check after each — a bad pattern caught at ten products is cheap; at a thousand it is a rollback.
- **Preview every write**; never chain `bulkUpdateProducts` calls without a fresh preview.
- **Touch only the fields the user asked about.** Rewriting a title is not licence to "tidy" the description.
- **Never blank a value.** If a draft is empty or you are unsure, leave the existing value — the same instinct as the platform's `skipEmpty` import setting. Clearing a field is a separate, explicitly confirmed action.
- Keep a record of before/after values for the batch so the change can be reversed.

## Transformations live in the mapping, not the data

If the "fix" is mechanical — upper/lower case, concatenating brand + title, converting units, swapping your value for the channel's accepted term — do **not** rewrite the catalog. Recommend a template convert rule (`FUNC:CASE`, `FUNC:CONCAT`, `FUNC:VALIDVALUE`, `FUNC:IF_THEN`, and the rest) so the master data stays clean and every channel renders correctly. Rewrite catalog data only when the content itself is wrong or missing. See `syndic8-templates`.

## Channel-specific variants are overrides, not overwrites

A retailer-specific title or description is **per-destination data**, stored as a Trading Partner Override row on the product (Product → Trading Partner Overrides in the app) rather than in the base field. The export for that destination reads the override; every other channel still reads the base. Putting a channel-shaped title into the base field fixes one channel and breaks the others. When the user wants channel-specific copy for several retailers, write each to its destination's override and keep the base neutral. See `syndic8-trading-partners` for how overrides are managed; if a bulk tool does not accept a destination scope, route the override load through the app screen or an import.

## Gotchas

- **Valid values are strict.** A value that reads right but is not in the channel's set fails the row. Check with the `getBrandValidValue*` tools before setting constrained attributes; prefer a `FUNC:VALIDVALUE` pairing over editing product data.
- **Max length is enforced on the exported field, after mapping.** A convert rule that prepends the brand can push an in-limit title over the cap — check the template field, not just the raw value.
- **Base vs override.** If a title "fixed" for one channel suddenly looks wrong on another, it was written to the base field. Move it to the override and restore the base.
- **Encoding.** Some channels reject smart quotes, em dashes, and other non-ASCII characters in titles and bullets. Default to plain ASCII unless the channel guideline allows more.
- **Preflight needs a collection.** A whole-catalog preflight buries the signal and may return nothing useful — scope it.
- **"Score" is ambiguous.** Your content assessment and the platform's scoring template are different numbers. Name which one you are reporting.
- **Write success is not proof.** After `bulkUpdateProducts`, re-query a sample and re-run preflight — treat the preflight row, not the update response, as the gate.

## Related skills

- `syndic8-pim` — product model, describe/query tools, safe update pattern
- `syndic8-templates` — template fields, convert rules, valid-value pairings, inheritance
- `syndic8-trading-partners` — destinations and Trading Partner Overrides
- `syndic8-media` — hero flag, image matching, image preflight
- `syndic8-data-audit` — audit scores, category assignment, reading preflight

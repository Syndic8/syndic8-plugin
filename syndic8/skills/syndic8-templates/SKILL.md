---
name: syndic8-templates
description: |
  Configure and understand Syndic8 export and import (DataLoad) templates. Use whenever the user mentions templates, field mapping, convert rules or transformation functions (FUNC:…), valid values or allowed values, template inheritance / parent templates / override flags, scoring templates or content scores, seed files or retailer spreadsheets, template status, Template Admin, or the Trading Partner screen's Field Mapping tab — or asks why an exported column came out blank, wrong, or untransformed. For the inheritance chain itself and the product model, see `syndic8-pim`; for preflight and audit interpretation, `syndic8-data-audit`; for channel connections, `syndic8-trading-partners`.
---

# Syndic8 Templates

A **template** is the configuration unit that defines how product data moves between Syndic8 and a trading partner: which Syndic8 field feeds which retailer column, how the value is transformed on the way, what fills in when the source is blank, and which columns are required. Every channel has at least one, and every import flow is driven by one.

This skill owns the template *domain*: field definitions, the convert-rule language, inheritance in practice, valid values, the seed-file workflow, and scoring templates. The inheritance *chain* (how a parent name resolves, which definition wins) is explained in `syndic8-pim` → `references/platform-model.md` → "Templates and inheritance"; this skill builds on it rather than repeating it.

**Read tools:** `listTemplates`, `listParentTemplates`, `getTemplateOverview` (always first), `listTemplateFields`, `getFieldMappings`, `compareTemplates`, `diagnoseField`. **App:** Template Admin (`/org/{orgId}/template`) and Trading Partners (`/org/{orgId}/channel`) → Field Mapping tab.

## A typical investigation

1. `listTemplates` (or `listParentTemplates` for the channel library) to find the template; note whether it is a child and of what.
2. `getTemplateOverview` — field count, how many are mapped, required, carry convert rules; status; parent; scoring link.
3. `listTemplateFields` / `getFieldMappings` for the fields in question — source, output name, rules, default, data type.
4. `compareTemplates` child vs parent when a change "isn't showing" — it exposes which definition is winning.
5. `diagnoseField` on a product that should be affected — mapping, requirement config, or source population?
6. `runPreflight` scoped to a collection; then an export, opened. Only the file proves a template.

Lead with the answer and the field(s) involved; show rules and mappings in tables; never guess a field or valid value — discover it with the tools.

## Export vs DataLoad (import) templates

| | Export template | DataLoad (import) template |
|---|---|---|
| Direction | Syndic8 fields → retailer columns | inbound file columns → Syndic8 fields |
| Source field | a Syndic8 internal field, or **no column** (static / computed) | an inbound column — every field is column-mapped |
| Destination column | the retailer's header (e.g. `item_name`, `Bullet Point`) | a Syndic8 internal field (`SKU`, `UPC`, `PRODUCTNAME`) |
| Transformations | rich convert rules (valid values, concatenation, pricing lookups) | usually light; valid-value rules for fixed-taxonomy fields such as product type |
| Parent | usually a child of a channel library parent | often standalone; partner-integration flows inherit from a partner import parent |
| Size | hundreds of fields for major retailers | as wide as the inbound file |

## The field definition, in plain terms

Each template field carries a handful of settings that decide what lands in its column:

| Setting | What it does | Where you see it |
|---|---|---|
| **Source field** | the Syndic8 field (or inbound column) the value comes from; "no column" means static or computed | Field Mapping tab, `getFieldMappings` |
| **Destination column** (output name) | the exact header the retailer sees, or the Syndic8 field an import writes | `listTemplateFields` |
| **Convert rule(s)** | an ordered list of `FUNC:…` transformations — the output of one feeds the next | field editor, `getFieldMappings` |
| **Static default** | used **only when the mapped source is blank**; never overrides a populated value | field editor |
| **Required flag** | marks the column required for preflight and the retailer | field editor, `runPreflight` |
| **Data type** | `String`, `Integer`, `Decimal`, `Date`, `Boolean` — governs which converts actually run (see below) | field editor |
| **Comment** | free text explaining a non-obvious mapping — fill it in; reviewers rely on it | field editor |

★ **Repeated retailer headers need distinct destination names.** If a retailer's file repeats a header (five `Bullet Point` columns), give each template field its own output name (`Bullet Point`, `Bullet Point 2`, …) — otherwise every column receives the same value even with different source fields. With a seed file attached, the retailer still sees its own repeated header text.

★ **Do not hardcode content manipulation on description and bullet fields.** The in-app copilot optimizes those; a hardcoded suffix or rewrite collides with it. Channel-specific voice belongs on the product-name field via `FUNC:CONCAT`.

## Convert rules

Transformations live in the mapping, not in the data — when output must differ from what is stored, add a rule rather than editing the catalog. Rules are processed **in order**; variables: `$D{FIELD}` = product data field, `$F{Field Name}` = another field on the same template, `$V{Var}` = a system or saved variable.

The complete function reference, with syntax and examples for every family, is in [references/convert-functions.md](references/convert-functions.md). The families at a glance:

| Family | Functions | Typical use |
|---|---|---|
| String | `CONCAT`, `CONCATDELIMITER`, `REPLACE`, `BEGIN_REPLACE`/`END_REPLACE`, `SUBSTR`, `TOUPPER`/`TOLOWER`/`TOPROPER`, `REMOVESPECIALCHAR`, `REGEX`, `FORMAT`, `COUNTSTRING`, `SHOPIFYHANDLE` | compose titles, clean text, split multi-values |
| Math | `MATH`, `FIELDMATH`, `EXCELFORMULA` | unit conversions, price arithmetic |
| Date | `CURRENTDATE`/`TODAY`, `TODAYTIME`, `MONTH`, `QUARTER`, `SEMIANNUAL`, `ANNUAL` | stamps and period labels |
| Conditional | `IF_THEN`, `CASE` | branch on another field's value |
| Lookup | `VALIDVALUE`, `REFERENCETABLE`, `GETPRICING`, `GETLANGUAGE`, `ISOCOUNTRY`, `WEIGHT`, `WHOLESALEDISCOUNT` | controlled vocabularies, prices, codes |
| Image | `IMAGE`, `IMAGELIST`, `IMAGEMULTILIST`, `IMAGETHUMB`, … | image URLs by tag |
| Content / other | `FORMATMARKETING`, `FIELDROLLUP`, `GENERATEVALUE`, `JAVASCRIPTEVAL`, `SAVEVAR` | bullets/description formatting, rollups, custom logic |

★ **`FUNC:MATH` does nothing on a `String` field.** The raw value passes through unchanged and no error is raised — a `String` price field with `FUNC:MATH:*::2` exports the unmultiplied value. Math converts need data type `Decimal` or `Integer`. When you copy a convert rule from another field or template, copy its data type too. If a math rule "isn't applying", check the data type before the rule.

Use `getFieldMappings` / `listTemplateFields` to read existing rules and `diagnoseField` to see how one field's rule resolves for real products.

## Inheritance in practice

A customer org's template is normally a **child of a channel library parent**, created from the Trading Partner screen → Field Mapping tab → "Create new manually" → pick the **Parent Template** and an **Inheritance Mode** → "Copy Parent". The resolution rules are in `syndic8-pim`'s platform model; what follows is how to work with them day to day.

**The two Inheritance Modes, as the UI names them:**

| Mode | Who owns the field list | Pick it when |
|---|---|---|
| **All Changes** (default) | the child — each field resolves individually (override → child's definition; not flagged → parent's) | the child adds any field of its own |
| **Field Mappings Only** | the parent — its field list **and order** govern output; child contributes only flagged overrides; **a child-only field is dropped** | the child is a strict subset and the channel's column order is fixed |

**Override flag semantics.** A child edit only wins when the field is **flagged as a parent override**. Unflagged, the parent's definition is used at export — mapping included — even though the edit saved without error. If a change "saved but didn't stick", check the flag first; `compareTemplates` shows where child and parent diverge. The flag is also a pin: a flagged field is immune to later parent changes.

★ **Flag fields before you attach a parent.** When a parent is attached to a working child whose fields are not flagged, export columns can come out blank: the parent's definition — including its source mapping — replaces the child's for every same-named field, and a parent that is still a bare schema (no source mappings yet) asserts "no source" for all of them. Only child-only fields and fields whose parent definition is a static literal survive. The plain practice:

1. Check the parent's maturity (`getTemplateOverview`, `listTemplateFields` — are its fields actually mapped?). Never attach a child to an unfinished parent.
2. Flag every field the child genuinely needs as a parent override **before** attaching.
3. Attach, export, and **open the file** — count blank columns against a pre-attach export. A preflight will not show this failure.
4. Use **All Changes** at every level of a multi-level chain; put the things a level genuinely owns in as **static defaults**, which is what reliably flows down.

**Sweep inherited static defaults** after copying a parent. Parents carry defaults from prior use — vendor codes, contact details, even another brand's name. Review every inherited default in a new child before its first export.

**Keep children thin.** A child that re-declares the parent's full mapping set has stopped inheriting; a healthy child is the parent plus the handful of fields the org genuinely does differently. What a parent is reliably good for: constants, requirement flags, conditions, column order, and lineage.

**Client override overlay.** Separate from the parent chain, a template can name a brand-level override template that is applied *after* the chain — for cross-category brand decisions (voice, warranty text, contact details) that must beat channel defaults. It substitutes same-named fields only, cannot add fields, and no override flag defends against it — so it must contain **only fields it genuinely decides, each properly mapped**.

## Template status lifecycle

Template Admin exposes a status that tracks implementation progress:

`Not Started` → `Attribute Mapping in Progress` → `Valid Values Mapping in Progress` → `Image Mapping in Progress` → `Testing in Progress` → `Pending Internal Review` → `Pending Signoff` → `Live`

- Only **Live** templates are treated as production-ready by the platform's export and preflight paths; anything else runs as in-progress work. Put `status = Live` in the definition of done, next to the scoring link and the opened export file.
- **Status and the `isLive` toggle are independent** — setting status to Live does not flip `isLive`.
- **Re-check status after replacing a template's seed file** or re-uploading its definition — it can revert to `Not Started`. Make the status change the last step.
- A raw retailer schema that has just been pulled is 0% mapped by construction — it belongs at `Not Started`, and mapping it is the "Attribute Mapping in Progress" step.

## Valid values

Valid values map the brand's vocabulary to each channel's accepted values (brand stores `COLOR = Red`, the channel wants `Crimson`). The `FUNC:VALIDVALUE` convert does the lookup at export; pairings are maintained on the Trading Partner screen.

**Typed (product-type-scoped) valid values.** A template carries a product type (a matrix top-level type), a sub-type (a matrix leaf) and the **destination's** product type (e.g. `FAUCET`). Valid values are designed to be typed end-to-end:

- **Scoped function** — the 5-part form `FUNC:VALIDVALUE::$D{FIELD}::Display Name::COLUMN::CATEGORY`, where `CATEGORY` is the destination's product type. The 1-part form `FUNC:VALIDVALUE::$D{FIELD}` resolves only untyped vocabulary.
- Product-type matching is **case-insensitive** (`Faucet` ≡ `FAUCET`), but a typed context resolves **only typed pairings** — untyped pairings do not fall back in. Under the typed model every brand value needs a pairing to a typed vocabulary row; mixing one typed and one untyped pairing on the same field leaves one of them invisible.
- **Bulk conversion is built in:** Template Admin → Actions → **Convert VV to Product-Type** / **Reset VV to Generic** rewrites every generic VALIDVALUE function on the template using its product type. Per field: the field's menu → Text Edit.
- **The seed's "Valid Values" sheet is the vocabulary source of truth.** A field absent there is free text — give it no pairings. A scoped VALIDVALUE on a free-text field is harmless: no match, value passes through.

**How brand values match.** Pairings are keyed on the brand value, the internal column and the destination. Design pairings against the field the destination actually pairs on (for colour on Amazon that is `Color Map`, fed from the generic colour field — not `COLOR`), and confirm that target field carries a `FUNC:VALIDVALUE` convert **before** choosing values.

**Tools:** `getValidValueColumns` (which columns carry valid values), `getValidValueFieldMappings` (field → valid-value column), `getBrandValidValueCounts` (matched vs unmatched per field — the truthful summary), `getBrandValidValueMatches`, `getBrandValidValueNotMatched` (candidates still to pair). Confirm a pairing with `getBrandValidValueCounts` or a preflight rather than the not-matched list alone. Maintaining pairings needs the **Allowed Values** role function on the org — a permission denial names it (see `syndic8-pim` → roles).

**Reference-table lookups** are the general-purpose alternative when the mapping is not a channel picklist (country name → ISO code, category code tables): `FUNC:REFERENCETABLE::TableName;returnField;param=$D{FIELD}`, tables maintained on the Reference Tables screen. A lookup miss yields an **empty cell with no warning** — see `syndic8-data-audit`.

## Seed file → template workflow

The retailer's own template spreadsheet (the **seed**) is the source of truth for a channel build. Always use the retailer's real download — for Amazon, the genuine category template is an `.xlsm` with its supporting sheets; a trimmed `.xlsx` copy has lost sheets and columns, silently.

1. **Analyze the seed.** Identify the fillable sheet vs supporting sheets (dropdowns, valid values, macros); the header row (the one with the most populated cells); required markers (`*`, colour-coding); every column; every dropdown value, including hidden sheets and named ranges; conditional requirements; image requirements.
2. **Map to Syndic8 fields.** Standard columns map to the internal model: UPC/EAN/GTIN → `UPC`; SKU / Vendor Part # → `SKU`; Title → `PRODUCTNAME`; Brand → `BRAND`; Long description → `PRODUCTDESCRIPTION`; Bullets/Features → `BULLET1…`; MSRP → `MSRP`; MAP → `MAP`; Color/Size → `COLOR`/`SIZE`; ship weight and L/W/H → `SHIPPINGWEIGHT`, `SHIPPINGLENGTH/WIDTH/HEIGHT`; Country of Origin → `COUNTRYOFORIGIN`; images → `MAINIMAGEURL`, `ALTIMAGEURL1…`. Confirm names with `listAvailableFields` — never guess. Columns with no counterpart become unmapped fields filled by static defaults, overrides or manual entry. Mapping is deliberately not 1:1 — shape outbound values with convert rules.
3. **Build in the wizard.** Trading Partner screen → Field Mapping tab → create from the retailer's library parent (flagging as above) or from the seed; the wizard's auto-match suggests internal fields. Pick the granular retailer category — that also syncs the metadata matrix so audits score the right field set (`syndic8-data-audit`).
4. **Configure valid values** for every dropdown column, scoped to the template's product type.
5. **Verify.** `runPreflight` scoped to a collection, then run an export and **open the file**: row count right, transforms applied, no blank columns, repeated headers carrying distinct values.

## Scoring templates

Every channel build has a **scoring template** alongside its export template: the rule set preflight uses to score content quality for that channel and category, instead of the platform's generic rules.

- A scoring template is a set of **pillars** (Title, Bullets, Images, Required Attributes, …), each weighted, each holding rules (`Length`, `Count`, `Match`, `Percent`, …) against named template columns. Pillar weights sum to 1.00.
- It is **linked** on Template Details → **"parent scoring template"**. Unlinked templates are still scored — against the platform-default rule set — so linking is what makes the channel-specific rules apply. The link is by file name; renaming the scoring file breaks it silently.
- **Rule fields match template output names exactly** — case-sensitive, no space/underscore folding, no substring. A rule whose fields do not resolve free-passes at 100 without any warning, so an all-100 readout is a suspect signal, not a clean one. When a score looks too good, diff the rule's field names against `listTemplateFields` output names.
- **Reading a score:** the preflight shows the weighted total plus per-pillar results; a `SCORING` category in the error summary lists which rules a product failed. Prove a rule works by outcome — a known-bad product should move the score.
- Admin screen: `/org/{orgId}/admin/scoring-templates`.

## Symptom → first thing to check

| Symptom | Most likely cause | Check |
|---|---|---|
| An exported column is completely blank | unflagged child field inheriting a parent mapping, or an unmapped field with no default | override flag; `getFieldMappings` source for that field |
| Several blank columns right after attaching a parent | parent is unfinished (fields not mapped) and the child's fields were not flagged | parent maturity; flag and re-export |
| A mapping change saved but the export didn't change | field is not flagged as a parent override | `compareTemplates` child vs parent |
| A math convert "isn't applying" | field data type is `String` | data type → `Decimal`/`Integer` |
| A valid value isn't translated | pairing missing for the template's product type, or the rule is on a different field than the pairing surface | `getBrandValidValueCounts`; which field carries `FUNC:VALIDVALUE` |
| A lookup column is intermittently empty | `REFERENCETABLE` miss (silent) | table name and key values; `syndic8-data-audit` |
| Five repeated columns all show the same value | identical output names | give each field a distinct output name |
| Content score reads 100 for everything | scoring rule fields don't match output names (exact, case-sensitive), so rules free-pass | diff rule fields vs `listTemplateFields` output names |
| Channel-specific scoring isn't applied | scoring template not linked on Template Details | "parent scoring template" picker |
| Preflight looks fine but the UI treats the template as in progress | status is not `Live` (it may have reverted after a seed/definition upload) | Template Admin status; set it last |
| Re-import didn't clear a field | `skipEmpty` default on the import flow | `syndic8-import-export` |

## Advanced: controlled API reads

When no MCP tool returns what you need (for example the full template object with its block structure), `callApiRead` can issue a GET:

- Paths are **org-scoped**: `org/{orgId}/template/{templateId}` for a template, `org/{orgId}/template` for the list. Pass query parameters in the tool's `query` argument, not in the path. No whitespace in paths.
- Read before you reason: the template object you get back is the merged view the app renders, including inherited definitions.

**Writes — prefer the app.** If `callApiWrite` is the only route: read the object first, show the user the **exact** before/after, get confirmation, write, then re-read to confirm it landed. Template field edits are **full-object PUTs** — send the whole field object back with your change applied, including its `blockName` (the block the field lives in); a partial body drops what it omits.

## Related skills

- **syndic8-pim** — product model, the inheritance chain, transformation summary, roles.
- **syndic8-data-audit** — preflight interpretation, category assignment, reference tables.
- **syndic8-trading-partners** — channel connections, collections, valid-value pairing surface.
- **syndic8-import-export** — running the imports and exports these templates drive.

# Syndic8 platform model — reference

Durable platform knowledge for working with Syndic8 product data, imports, templates, and readiness checks. Read the relevant section before advising on data modeling, catalog loading, or mapping work.

## Product hierarchy: style → SKU → UPC

Syndic8 models products on three levels:

- **Product = style.** The top-level record (e.g. "Trailblazer Hiking Boot").
- **SKU = colorway.** One style has many SKUs — one per color/variant.
- **UPC = size.** One SKU has many UPCs — one per size. **UPC is the unique identifier** for an item.

Rules that follow from this:

- **Always populate `STYLENUMBER`** on every size record so sizes roll up under their style. Image auto-matching and catalog rollup both depend on it — records without a style number appear as disconnected one-offs.
- **Images match at the SKU (color) level.** An image matched to a colorway is shared by all of that color's sizes. You do not (and should not) match images size-by-size.
- **Do not model every size as its own SKU.** That flattens the hierarchy: rollup breaks (each size shows as an unrelated product) and image matching breaks (images no longer fan out across sizes). If a catalog looks like thousands of single-size "products", this is usually why.

When diagnosing "products look duplicated" or "images only attached to some sizes", check the hierarchy first: is `STYLENUMBER` populated, and are colors (not sizes) modeled as SKUs?

## Product types: a fixed, platform-wide taxonomy

Product types in Syndic8 are a **fixed taxonomy defined at the platform level**. You cannot create new types, and imports/updates with an unknown type are rejected with an error like:

> Product type 'X' is not defined for this organization

The message is worded per-organization, but the taxonomy itself is platform-wide — no org can add types.

- **Exact strings matter.** For example, footwear is `Shoes` — sending `Footwear` is rejected even though it's semantically identical.
- **Fix it in the mapping, not the data.** When a source system uses different type names, map them to a valid Syndic8 type in the import configuration using a valid-value / convert rule. Do not ask the customer to edit their source files — the mapping is the durable fix and survives every future import.

## Import-first loading

Complete, fully-functional products — editable fields, media auto-matching, pricing — come from the platform's **import flows**, not from API-style creation.

- `createProduct` creates an **identity-only record**: fine for a quick test or a one-off placeholder, wrong for loading a catalog. Products created this way lack the field population and matching behavior that imported products get.
- **Load order matters.** Later loads match against earlier ones:
  1. **Product attributes** first (establishes styles/SKUs/UPCs),
  2. then **pricing** (matched by SKU/UPC),
  3. then **marketing** content,
  4. then **images** (auto-matched at the SKU/color level).
- **`skipEmpty` defaults to TRUE**: blank values in an inbound file do **not** overwrite saved values. This protects existing data during partial or incremental loads. Only set it FALSE temporarily, and only for a deliberate clean-slate reload where blanks are meant to erase — then set it back.

If a customer asks why a re-import "didn't clear" a field: `skipEmpty` is almost always the answer.

## Brand attribution (multi-brand organizations)

In a house-of-brands setup, a product's **brand is a product-level assignment set at import time** — it resolves through a brand organization with a matching name.

- **Include the brand column in the product import** from the start.
- Do not try to bolt brand on later via template static defaults or post-hoc edits — brand attribution drives valid-value matching (see the `getBrandValidValue*` tools) and channel behavior, and it belongs on the product record.

## Templates and inheritance

Templates are parent/child:

- **Library parent templates** live with the destination/channel and encode the channel's requirements.
- A customer org's template is a **child** created from the parent. In the app: **Trading Partner screen → Field Mapping tab → "Create new manually"** wizard — pick the **Parent Template** and an **Inheritance Mode**, then **"Copy Parent"** performs the creation.
  - **"Field Mappings Only"** — the child inherits field mappings; other parent changes don't flow down.
  - **"All Changes"** — the child tracks all parent changes.

Two behaviors that surprise people:

1. **Child edits only take effect when flagged as a parent override.** A child field overrides the parent only when it is explicitly marked as an override — otherwise the parent's definition wins at render time *even though the child edit saves without error*. If an edit "saves but doesn't stick" in output, check the override flag before anything else. `compareTemplates` helps show where child and parent diverge.
2. **Sweep inherited static defaults after copying a parent.** Parent templates can carry static default values from prior use (including another brand's values — brand names, contact info, defaults). Review every inherited static default in a new child template before first export.

## Transformations: the mapping engine's muscle

Transformation rules live **in the template mapping, not in the product data**. When output needs to differ from stored values, reach for a mapping rule — don't rewrite the catalog.

Variable syntax: `$D{X}` = a product data field; `$F{X}` = another field on the same template.

Key rule families:

| Rule | Syntax | Use |
|---|---|---|
| Valid-value mapping | `FUNC:VALIDVALUE::$D{FIELD}::Display::COL::CATEGORY` | Map internal values to the channel's controlled vocabulary |
| Conditional | `FUNC:IF_THEN:'$D{FIELD}' == ''::then::else` | Branching logic. With an empty-test condition, the **then** branch fires when the field is blank — e.g. derive an item type per category from a distinguishing attribute |
| Reference table | `FUNC:REFERENCETABLE::Table;OutCol;InCol=$D{FIELD}` | Cross-table lookups, e.g. country name → ISO code |
| Concatenation | `FUNC:CONCAT` | Join fields/literals into one output value |
| Case mapping | `FUNC:CASE` | Multi-way value switches |
| Pricing lookup | `FUNC:GETPRICING` | Pull a price into a template field |

Use `getFieldMappings` and `listTemplateFields` to read existing rules, and `diagnoseField` to see how a specific field's rule resolves for real products.

## Preflight workflow

A repeatable readiness loop:

1. **Scope `runPreflight` to a collection.** Running against a whole catalog buries the signal; a collection scoped to the products actually going to the channel gives a meaningful gap report. (Same for `runImagePreflight`.)
2. **Read the gap report in three buckets:** required-missing (blocking), recommended (quality), and invalid-values (data present but not channel-accepted).
3. **`diagnoseField` on any flagged field** to determine which layer is at fault: the mapping (transformation rule wrong or missing), the required-config (field required/valid-value setup), or source-field population (the product data itself is blank or wrong).
4. **Fix at the right layer, then re-run** preflight until green. Mapping problems get mapping fixes; data problems get import fixes — don't paper over a mapping bug with a data edit (or vice versa).

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
- **First check whether your catalog actually has three tiers.** The style → SKU → UPC model is
  apparel-shaped. Some catalogs genuinely have only two levels — a tire line and its individual
  sizes, for example, where each size is a distinct sellable item and nothing sits between them.
  There, one SKU per item is correct, not a modelling error. Test it by counting how many items
  share a (product name, variant) pair: if almost none do, there is no middle tier to model, and
  forcing one creates groups of one.
- **Where a middle tier DOES exist, do not model every size as its own SKU.** That flattens the hierarchy: rollup breaks (each size shows as an unrelated product) and image matching breaks (images no longer fan out across sizes). If a catalog looks like thousands of single-size "products", this is usually why.

When diagnosing "products look duplicated" or "images only attached to some sizes", check the hierarchy first: is `STYLENUMBER` populated, and are colors (not sizes) modeled as SKUs?

### The All Products grouping selector

The product list has a dropdown that switches which tier you are looking at:

| Option | Groups by | Shows |
|---|---|---|
| **Styles** | product name | one tile per style |
| **SKUs** | SKU | one tile per colorway, labelled with its **Color** |
| **UPCs** | the individual item | one row per item |
| **Custom Assortment** | the product's **Product Group** field | one tile per group |

Two things follow that regularly surprise people:

- **The SKU tier labels each tile with `Color`.** It is the only variant attribute shown at that
  level. If `Color` is empty, those tiles have no label — even though the grouping itself still
  works. `Size` is only shown at the UPC tier.
- **The grouping resets to Styles.** The selection lives in the page URL, so it is not remembered
  between visits or shared across screens. Treat Custom Assortment as an occasional analytical
  cut, not as a catalog's day-to-day navigation.

### Non-apparel catalogs: where does the variant axis go?

The default tiers are apparel-shaped (style → colorway → size). For a catalog whose variants are
not colors — tire sizes, capacities, lengths, voltages — map the tiers like this:

| Tier | Apparel | Non-apparel (e.g. tires) |
|---|---|---|
| **Style** (product name + `STYLENUMBER`) | the style | the product line (`Defender LTX M/S`) |
| **SKU** | the colorway | **the variant** — each tire size, capacity, voltage |
| **UPC** | the size | the sellable item; when the variant *is* the item, SKU and UPC are one-to-one, and that is correct |

Rules that follow:

1. **The SKU tier is always the variant level, whatever your variant is.** Do **not** make the
   product line the SKU with sizes as its UPCs — that collapses every variant into one tile with
   one label, and the sizes become invisible until the UPC tier.
2. **One SKU per item is not a modelling error** when nothing sits between the line and the item.
   The apparel warning against "one SKU per size" applies only where a real middle tier (a
   colorway) exists and is being flattened.
3. **Images**: line-level photos that apply to every size are matched once at the style level with
   the media **Multi Match** setting on (see `syndic8-media`), so each size SKU still shows the
   image.
4. **Put the variant label in `Color`** so it appears on the SKU tile. It is a display convention,
   not a model — document it at the field, or someone will later "clean up" a `Color` full of
   tire sizes and blank every tile.
5. **`Product Group`** adds a Custom Assortment tier for an extra analytical cut, but the dropdown
   resets to Styles on every visit, so it does not replace rule 1.

Putting the variant in `Size` alone is unsatisfying: it does not appear on the SKU tier at all,
and size ordering is driven by a separate sort-order value, so unfamiliar values sort
unpredictably until that is populated too.

## Product types: a fixed, platform-wide taxonomy

Product types in Syndic8 are a **fixed taxonomy defined at the platform level**. You cannot create new types, and imports/updates with an unknown type are rejected with an error like:

> Product type 'X' is not defined for this organization

The message is worded per-organization, but the taxonomy itself is platform-wide — no org can add types.

- **Exact strings matter.** For example, footwear is `Shoes` — sending `Footwear` is rejected even though it's semantically identical.
- **Discover the taxonomy with `listProductTypes`** — never by trial-and-error creates.
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

**A field's `defaultValue` fires only when its mapped source cell is blank — it never overrides a
populated value.** A field can carry both a source-column mapping and a default at the same time;
if the mapped cell has a value, that value is used verbatim regardless of the default. This matters
most on fixed-taxonomy fields (e.g. product type): a template can have a perfectly valid default set,
but if it's *also* mapped to a source column full of the customer's own category labels, every row
imports with the customer's label — and an unrecognized one fails validation even though the
"correct" default was right there. Fix it in the mapping: either unmap the source column (let the
default apply uniformly), or add a valid-value / reference-table convert rule to translate the
customer's vocabulary to the fixed taxonomy per row — a default alone can't do that translation,
it's all-or-nothing, not a per-value lookup.

## Brand attribution (multi-brand organizations)

In a house-of-brands setup, a product's **brand is a product-level assignment set at import time** — it resolves through a brand organization with a matching name.

- **Include the brand column in the product import** from the start.
- Do not try to bolt brand on later via template static defaults or post-hoc edits — brand attribution drives valid-value matching (see the `getBrandValidValue*` tools) and channel behavior, and it belongs on the product record.

## Templates and inheritance

Templates form an **inheritance chain**, resolved fresh on every export. Understanding it is the
difference between a mapping change that takes effect and one that silently does nothing.

### The chain

- **Library parent templates** live with the destination/channel and encode the channel's
  requirements — every field, its mapping, defaults and conditions.
- A customer org's template is a **child** of one. In the app: **Trading Partner screen → Field
  Mapping tab → "Create new manually"** — pick the **Parent Template** and an **Inheritance
  Mode**, then **"Copy Parent"**.
  - **"All Changes"** (the default) — the child keeps **its own field list**. For each field it
    has, an overridden field keeps the child's definition and a non-overridden one takes the
    parent's. Fields the child added that the parent doesn't have are left alone.
  - **"Field Mappings Only"** — the **parent's field list and order govern** the output. The
    child contributes only the fields it has explicitly overridden; **a field the child added
    that the parent doesn't have is dropped from the export.**

  Read those names carefully — they are easy to get backwards. "Field Mappings Only" is the
  *stricter* mode: it hands control of which columns exist, and in what order, to the parent.
  If your child adds any field of its own, choose **"All Changes"**.

**Depth is unlimited.** A child's parent may itself have a parent, and so on — child → parent →
grandparent → beyond. The chain is walked until a template has no parent, with a guard that stops
a template naming itself. So a customer can hold their own base template of shared, pinned
decisions (brand voice, price rules, image slots) and give each product category a small child
that overrides only what differs. Use depth where it removes duplication; every extra level is
one more place someone has to look.

### How a parent name resolves — four levels, most specific wins

A parent is referenced **by name**, and that name is looked up in a fixed order, stopping at the
first org that has it:

1. the **customer org** itself
2. the **destination/channel** org
3. the **parent org / firm**
4. **Syndic8 global**

This is what makes shared templates practical: Syndic8 publishes a global template, and any
customer, firm or channel can override it *for themselves* by creating one with the same name at
their own level. Nothing else has to change — the next export picks up the nearer one. It also
means a name collision at a nearer level silently shadows the global, so keep names deliberate.

### Which definition wins, field by field

For each field in the child, on every export:

| Child field | What exports |
|---|---|
| marked as a **parent override** | the child's own definition |
| not marked, and the parent has a field of the same name | **the parent's definition** |
| not marked, and the parent has no such field | the child's definition |

Two consequences worth internalising:

1. **A child edit only takes effect when the field is flagged as a parent override.** Otherwise
   the parent's definition wins at export *even though the child edit saved without error*. If a
   mapping change "saves but doesn't stick" in output, check the override flag before anything
   else. `compareTemplates` shows where child and parent diverge.

   This is worth taking seriously rather than filing away, because it is what a parent's
   definition *winning* actually means: the parent's **mapping** wins too. A library parent's
   mappings point at the source columns the library assumes, so a child that inherits them
   unflagged can export a column that is **completely empty** — the field looks configured, the
   export succeeds, and the data is gone. **Attach a parent, then export and check the file
   before trusting it.** If columns came back blank, flag the affected fields as parent
   overrides and re-export.
2. **The override flag is also a pin.** An overridden field is immune to later parent changes.
   That is the mechanism for "inherit improvements, but never let this one field move" — it is
   not just a way to change a mapping.

### Parent-driven field order

A parent can additionally assert **its own field list and order** over the child's, so the child
contributes only its overrides and the output column order is governed centrally. This is the
stronger form of inheritance: use it when the channel's column order is fixed and children should
not be able to reorder or omit columns.

There is also a separate **client forced override** layer, applied after the chain is walked, for
cases where one customer's template must win regardless of the hierarchy.

### Practical guidance

- **Keep children thin.** A healthy child carries the fields it needs plus its genuine overrides.
  A child that duplicates the parent's full mapping set has stopped inheriting in practice: every
  field either shadows the parent or is dead weight, and parent improvements stop reaching it.
- **Sweep inherited static defaults after copying a parent.** Parent templates can carry static
  defaults from prior use — including another brand's values (brand names, contact details).
  Review every inherited static default in a new child before its first export.
- **Detaching a child from its parent** makes it fully self-contained: nothing is inherited and
  nothing propagates. That is occasionally what you want, but it is a decision, not a default —
  a detached child will not pick up channel requirement changes.

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

## User roles & permissions

MCP tool calls run as a specific user and are bound by that user's **role on the organization being queried** — the same permission system that gates the UI, not a separate MCP-level allowlist. A tool being callable at all doesn't mean the calling user's role on a given org grants the function behind it.

- **A permission denial names the specific function it needs** (e.g. "Permission denied: 'Allowed Values' (Read) required"). Treat that as the actual diagnosis, not a generic auth failure — it points at exactly which role function is missing.
- **Roles are assigned per (user, organization)**, not globally per user. The same person can legitimately hold a full "Admin"-equivalent role on one org and a lower "Operations"/"User"-equivalent role on another — that's normal, not a bug. A newly created or promoted-into org can default a user to a lower role than they hold elsewhere; don't assume parity carries over.
- **When a call fails unexpectedly, check the role assignment before assuming a platform or config bug.** Org-level permission flags returned by some org-detail endpoints are often a derived, read-only view of what the current role grants — they don't explain *why*, and patching them directly may appear to succeed without changing the underlying access. The actual fix is correcting which role the user holds on that org.
- **Treat role reassignment as a sensitive, deliberate action** — read the current assignment first, change only what's needed, and verify by re-reading afterward rather than assuming a write succeeded.

---
name: syndic8-pim
description: |
  Work with Syndic8, the product content syndication platform — query and update product data, explore export/import templates and field mappings, run preflight readiness checks, manage collections, and look up inventory, pricing, and purchase orders. Use whenever the user mentions Syndic8, their PIM, product data, listings readiness, templates, valid values, preflight, or syndication to retail channels.
---

# Syndic8

Syndic8 is a product content syndication platform, backed by a built-in PIM/DAM: it centralizes product content and publishes it to retail channels (Amazon, Walmart, and many others). This skill covers working with your Syndic8 account through the **Syndic8 MCP server** bundled with this plugin.

## Connection & auth

All tools come from the `syndic8` MCP server (`https://mcp.syndic8.io/mcp`). The first use triggers an OAuth login with the user's Syndic8 credentials — they only see data their account can access. If tools are missing or unauthorized, ask the user to complete the connection/OAuth prompt for the Syndic8 server.

Start a session by orienting:
- `listOrganizations` — which orgs the user can work in (most tools take an org context)
- `getUserPermissions` — what the user is allowed to do
- `getMarketplaceList` — channels configured for the org

## Platform model — key rules

Full detail (with syntax and step-by-steps) in [references/platform-model.md](references/platform-model.md); the essentials:

- **Hierarchy**: product = style → SKU = colorway → UPC = size (UPC is the unique identifier). Populate `STYLENUMBER` so sizes roll up under the style — image auto-matching and catalog rollup depend on it. Images match at the SKU (color) level and are shared by that color's sizes. Where a colorway tier exists, never model each size as its own SKU — it breaks rollup and image matching. Where it doesn't (tires, capacities, voltages), the SKU **is** the variant and one SKU per item is correct — see the reference's non-apparel section.
- **Product types are a fixed, platform-wide taxonomy.** New types can't be created; unknown types are rejected ("Product type 'X' is not defined for this organization" — worded per-org, but the taxonomy is platform-wide). Exact strings matter (footwear is `Shoes`, not `Footwear`). Map source values to a valid type in the import configuration (valid-value / convert rule) — don't edit source data.
- **Import-first loading.** Complete products (editable fields, media matching, pricing) come from the platform's import flows; `createProduct` makes an identity-only record — fine for a quick test, wrong for loading a catalog. Load in order: product attributes → pricing (matched by SKU/UPC) → marketing → images. The `skipEmpty` import setting defaults TRUE: blank inbound values don't overwrite saved values (set FALSE only for a deliberate clean-slate reload).
- **Brand attribution** (multi-brand orgs): brand is a product-level assignment set at import, resolved through a matching-named brand organization. Include brand in the product import — don't bolt it on later via template defaults.
- **Template inheritance**: a customer org's template is a child of a library parent (created via the Trading Partner screen → Field Mapping tab wizard). A child field only overrides the parent when explicitly flagged as an override — otherwise the parent wins at render even though the edit saves. After copying a parent, sweep inherited static defaults (they may carry another brand's values).
- **Transformations live in the mapping, not the data** — `FUNC:VALIDVALUE`, `FUNC:IF_THEN`, `FUNC:REFERENCETABLE`, `FUNC:CONCAT`, `FUNC:CASE`, `FUNC:GETPRICING` (syntax in the reference). Prefer a mapping rule over rewriting catalog data.

## Product data

- Always call `describeProductFields` before building filters — field names are org-specific. The same applies to `describeInventoryFields`, `describePricingFields`, `describePurchaseOrderFields` for those domains.
- `queryProducts` for records; `queryProductAggregate` for counts/rollups (prefer aggregates for "how many" questions — cheaper and faster).
- `listProductTypes` for the valid product-type taxonomy and `listAvailableFields` for the org's field catalog — use these to discover valid values, never a trial `createProduct`.
- `createProduct` to add a quick test/placeholder product (identity-only — catalogs load via imports, see Platform model); `createProducts` for a small batch of the same; `diagnoseField` when a field's value or mapping looks wrong.
- `getFieldConfig` for one field's configuration; `queryMatrix` for the per-product-type field model (which fields a category requires/recommends); `getServerInfo` to confirm what server/version you're talking to.

## Inventory, pricing & purchase orders

Each domain pairs a describe tool with query tools — describe first, then query:

- **Inventory**: `describeInventoryFields` → `queryInventory` (records) / `queryInventoryAggregate` (totals by location, SKU, etc.).
- **Pricing**: `describePricingFields` → `queryPricing` / `queryPricingAggregate`. Pricing rows carry MSRP / MAP / wholesale cost per currency; channel-specific price overrides are separate rows scoped to a destination.
- **Purchase orders** (B2B commerce orgs): `describePurchaseOrderFields` → `queryPurchaseOrders` / `queryPurchaseOrderAggregate`.

### Updating products safely

1. `previewBulkUpdate` first — always show the user what will change and how many products are affected.
2. Only after the user confirms, `bulkUpdateProducts`.
3. `deactivateProducts` removes products from active use — confirm explicitly, and never run it on a filter you haven't previewed.

## Templates & field mappings

Templates define how product data maps to a channel's requirements.

- `listTemplates` / `listParentTemplates` to find them; `getTemplateOverview` before drilling in.
- `listTemplateFields` for field-level detail; `getFieldMappings` for source-to-destination mappings; `compareTemplates` to diff two templates.
- Valid values (channel-accepted values per field): `getValidValueColumns`, `getValidValueFieldMappings`, and the `getBrandValidValue*` tools to see matched/unmatched brand values.

## Readiness (preflight)

- Scope `runPreflight` to a collection for meaningful results — whole-catalog runs bury the signal. It checks products against a channel template's requirements and reports errors/warnings per field.
- `runImagePreflight` does the same for image requirements.
- Read the gap report as three buckets: required-missing (blocking), recommended (quality), invalid-values (present but not channel-accepted).
- Use `diagnoseField` on any flagged field to see whether the issue is the mapping, the required-config, or source-field population — fix at that layer, then re-run to green.
- Summarize results as: ready count, blocked count, top failing fields, and suggested fixes.

## Advanced: direct API access (`callApiRead` / `callApiWrite`)

Two general-purpose tools call the Syndic8 REST API under the user's own permissions, for the cases a dedicated tool doesn't cover (the full template object, sub-catalog listings, org configuration). Treat them as the last resort, not the first.

- **Read first, always.** `callApiRead` is safe: it is GET-only and returns the raw object. Use it to inspect before any change and to re-read after one.
- **Path rules**: the path must include the org segment (`org/{orgId}/...`); query parameters go in the `query` argument, never in the path; paths cannot contain whitespace. Use `listOrganizations` to get the org id.
- **Writes go through the app unless the user asks otherwise.** When `callApiWrite` is the right tool: read the object, show the user the exact fields that will change, get an explicit yes, write, then read it back and confirm the change landed. Many Syndic8 PUT routes replace the whole object — send the complete object with your edit applied, never a fragment.
- **Never use these tools to bypass a safety step** another tool enforces (previewing a bulk update, confirming a deletion), and never call a bulk route without an explicit list of the products it applies to.
- If a read returns an error about the route, say so and fall back to the app screen rather than guessing another path.

## Collections

Collections are named product groupings (sub-catalogs): `createCollection`, `updateCollection`, `addCollectionProducts`, `removeCollectionProducts`, `queryCollectionProducts`, `getCollectionDetail`, `deleteCollection` (confirm before deleting).

## App navigation (when pointing the user to the app)

The app lives at `app.syndic8.io`; screens are org-scoped. When handing off, name the screen and give the path:

| Screen | Path |
|---|---|
| Products | `/org/{orgId}/product` |
| Collections / Catalogs | `/org/{orgId}/catalog` |
| Media Management | `/org/{orgId}/image` |
| Import (upload + create wizards) | `/org/{orgId}/import` |
| Import History | `/org/{orgId}/import-history` |
| Templates | `/org/{orgId}/template` |
| Trading Partners | `/org/{orgId}/channel` |
| Data Audit | `/org/{orgId}/data-audit` |
| Verification | `/org/{orgId}/verification` |
| Metadata Matrices | `/org/{orgId}/metadata` |
| Reference Tables | `/org/{orgId}/freight-forwarding/reference-table` |

## Working style

- Lead with the answer, then the supporting data; use tables for product/field listings.
- Never fabricate field names or valid values — discover them with the describe/list tools.
- For destructive or bulk operations (bulk updates, deactivation, deletion), preview + explicit user confirmation, every time.
- If something needs Syndic8's in-app experience (imports, media upload, approvals), say so and point the user to the app — the in-app Syndic8 copilot can also help there.

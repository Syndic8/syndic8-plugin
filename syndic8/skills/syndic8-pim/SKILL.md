---
name: syndic8-pim
description: |
  Work with the Syndic8 PIM — query and update product data, explore export/import templates and field mappings, run preflight readiness checks, manage collections, and look up inventory, pricing, and purchase orders. Use whenever the user mentions Syndic8, their PIM, product data, listings readiness, templates, valid values, preflight, or syndication to retail channels.
---

# Syndic8 PIM

Syndic8 is a product information management (PIM) and syndication platform: it centralizes product content and publishes it to retail channels (Amazon, Walmart, and many others). This skill covers working with your Syndic8 account through the **Syndic8 MCP server** bundled with this plugin.

## Connection & auth

All tools come from the `syndic8` MCP server (`https://mcp.syndic8.io/mcp`). The first use triggers an OAuth login with the user's Syndic8 credentials — they only see data their account can access. If tools are missing or unauthorized, ask the user to complete the connection/OAuth prompt for the Syndic8 server.

Start a session by orienting:
- `listOrganizations` — which orgs the user can work in (most tools take an org context)
- `getUserPermissions` — what the user is allowed to do
- `getMarketplaceList` — channels configured for the org

## Product data

- Always call `describeProductFields` before building filters — field names are org-specific. The same applies to `describeInventoryFields`, `describePricingFields`, `describePurchaseOrderFields` for those domains.
- `queryProducts` for records; `queryProductAggregate` for counts/rollups (prefer aggregates for "how many" questions — cheaper and faster).
- `createProduct` to add products; `diagnoseField` when a field's value or mapping looks wrong.

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

- `runPreflight` checks products against a channel template's requirements and reports errors/warnings per field.
- `runImagePreflight` does the same for image requirements.
- Summarize results as: ready count, blocked count, top failing fields, and suggested fixes.

## Collections

Collections are named product groupings (sub-catalogs): `createCollection`, `updateCollection`, `addCollectionProducts`, `removeCollectionProducts`, `queryCollectionProducts`, `getCollectionDetail`, `deleteCollection` (confirm before deleting).

## Working style

- Lead with the answer, then the supporting data; use tables for product/field listings.
- Never fabricate field names or valid values — discover them with the describe/list tools.
- For destructive or bulk operations (bulk updates, deactivation, deletion), preview + explicit user confirmation, every time.
- If something needs Syndic8's in-app experience (imports, media upload, approvals), say so and point the user to the app — the in-app Syndic8 copilot can also help there.

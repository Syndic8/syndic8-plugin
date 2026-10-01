---
name: syndic8-trading-partners
description: |
  Syndic8 trading partners (destinations/channels) — how products flow to a retailer, what a channel connection actually is, connections (Amazon, Walmart, Shopify, SFTP) and their setup fields, collections/sub-catalogs, Trading Partner Overrides (per-destination product data), and troubleshooting connectivity. Use whenever the user mentions trading partners, destinations, channels, connecting a marketplace, Amazon/Walmart/Shopify connection, sub-catalogs, channel-specific titles or bullets, or the Trading Partners screen.
---

# Syndic8 Trading Partners

Trading partners (channels/destinations) are the retailers and marketplaces that receive product data.

## The data-flow chain

**Product → Collection (sub-catalog) → Destination (trading partner) → Template (mapping + transforms) → Export file/API.**

- A **channel** is the trading-partner record (Trading Partners screen, `/org/{orgId}/channel`); `getMarketplaceList` returns the org's configured channels, and `listDestinations` the destinations templates can target.
- A **collection connected to a destination** (a sub-catalog) scopes which products go to that channel.
- The **template** does the field mapping/transforms for that destination's format; templates are destination-scoped.
- A **connection** holds the credentials/config for transfer (SFTP, marketplace API, …); a **syndication schedule** runs a sub-catalog/destination pair's export automatically.

## Channel-connection anatomy

There is no separate "connection" object behind a channel's collection list: **a connection IS a collection whose destination is set.** That explains every behaviour below.

- **Connecting a collection moves it off the Collections screen** and under Trading Partners → the channel. Expected, not a loss: its membership stays queryable (`queryCollectionProducts`, `getCollectionDetail`) and grid filters still work. Plan for the move — a collection you also use for day-to-day work should be duplicated before connecting.
- **Disconnecting is not symmetric with connecting.** The channel's Disconnect / "Deactivate Trading Partner" action deletes the whole collection record, not just the link; there is no disconnect-only path. Products are untouched. To keep the membership, recreate the collection under a temporary name first, then disconnect, then rename. Fresh smart collections materialize membership asynchronously — wait before judging counts.
- **The template is not stored on the connection.** The export dialog offers a destination-filtered template picker and the operator chooses; carry the pairing by naming convention (a `Faucets` collection ↔ a `…Faucet Export` template). Every channel to the same destination lists all of that destination's templates.
- **One channel per destination is the intended pattern.** All channels to one destination share the same authorization, so extra channels add only a product scope — and read as alien configuration to anyone who knows the app. For product-type scoping, use one combined connection plus **per-type smart collections**, filter the channel grid by collection, and select-then-syndicate through the matching template. If a combined connection already exists, keep it: it carries the full-catalog preflight history and the channel's Field / Media / valid-value tab configuration.

## Connection patterns

- **Amazon** — Login-With-Amazon reverse-OAuth. Seller Central needs the Merchant Token (Seller ID); Vendor Central needs Vendor Code(s). Vendor authorization happens at the **vendor-group** level — one authorization covers every vendor code in the group (codes are 5 characters, one per buying relationship, listed under Vendor Central → Settings → Contacts). The channel's schema is retrieved automatically once auth is established.
- **Walmart** — the customer initiates from the Walmart app store by selecting Syndic8 as solution provider.
- **Shopify** — the customer creates a custom app in Shopify admin, grants the Admin API scopes Syndic8 requests (the product/inventory/media read-write set), and provides the **Admin API access token** (entered in the connection's `API Password` field) plus the **Storefront URL**.
- **SFTP** — Syndic8 maintains an SFTP site for file-drop syndication, with transmission notifications.

**Establish connectivity early** — locating admin access and credentials on the retailer side is routinely the longest lead-time item in going live on a channel.

### Connection Setup field semantics

- **Plugin Name** must exactly match the destination's integration plugin (e.g. `amazon-sp-plugin`, `walmart3p-plugin`, `shopify-plugin`, `export-plugin` for generic file export) — a mismatch silently breaks the export path with no error at setup time.
- **Out Flag = Yes** for outbound connections (exports); inbound file pickups leave it off.
- **Type = API** is required for marketplace report/feed-status retrieval to work; file connections use the file type.
- **Use New Path = Yes** enables the multi-login authorization path used by current marketplace integrations.

## Verifying a connection

Send something through it and read **Admin → Third-Party Messages**: 2xx = accepted by the retailer; 4xx = likely a payload/config problem on the Syndic8 side; 5xx = the retailer API's problem. Amazon can take up to ~24h to reflect a delivered feed. Retailer sandboxes are rare, so connection testing usually happens against the live channel: use delisted or zero-inventory test SKUs, guard prices on test items, and be especially careful with first-party price changes. A connection that shows "connected" but has never produced a 2xx is unproven.

## Trading Partner Overrides — per-destination product data

Retailer-specific content (an Amazon title, a Walmart title, channel bullets, a channel description, a per-channel wholesale cost) is **data**, and it lives on the product as a **Trading Partner Override**: one override row per (product, destination), edited on **Product → Trading Partner Overrides** (`/org/{orgId}/product/{id}?destination=<dest>`).

- **Use an override instead of changing master data** whenever a value is right for one retailer and wrong for the others. Putting an Amazon title in the base Product Title "works" for Amazon and corrupts every other channel's export.
- **Use a template convert instead** when the difference is a *formula* (truncate to 80 characters, prefix the brand, map a valid value) that applies to every product — overrides are for per-product wording and prices.
- **How it surfaces**: the override row carries the same field names as the base product (title, bullets, marketing description, keywords, short description, feature, prices). The export for that destination overlays the override on the base record, so a template field that reads Product Title gets the Amazon override on the Amazon export and the base value everywhere else — **no template change is needed** to adopt an override. Preflight for that destination evaluates the overlaid value.
- **Loading overrides from a file**: when a source file carries per-retailer columns (`Amazon Title`, `Walmart Title`, `Nordstrom Bullet 1–8` …), the column whose retailer is the primary channel becomes the base field; every other one loads as that retailer's override — and only for retailers that exist as destinations on the org. The override import maps those columns to the destination-scoped fields.
- **Verify** on the product's Trading Partner Overrides tab for that destination, then in the destination's preflight/export row — a saved row that doesn't appear in the export is not done.

## Sub-catalogs

- A **sub-catalog** is a collection scoped to a destination — the product set an export selects from. Build it as a smart collection (rule-based, re-evaluates automatically) when membership follows product attributes; as a static collection when it's a hand-picked assortment.
- Static sub-catalogs are a fixed set of product records: **after a product reload they can be empty**, and the next export is a "Complete" run of nothing (see `syndic8-import-export`). Re-check counts after any reload.
- Membership can also be driven from an import file (`Create Collection Name` / `Remove Missing Collections`, or the Sub Catalog import type) — collections and sub-catalogs are treated identically there.
- MCP: `queryCollection` / `getCollectionDetail` to inspect; `createCollection`, `addCollectionProducts`, `removeCollectionProducts`, `updateCollection` for hand-built membership; `runPreflight` scoped to the collection + destination for readiness.

## Troubleshooting connectivity

- **Export ran, retailer shows nothing**: check Third-Party Messages first (a 4xx is a payload problem, not a connection one), then the run's product count — an empty sub-catalog produces a clean run of nothing.
- **"Failed to retrieve schema" on a marketplace channel**: the authorization is incomplete or has lapsed on the retailer side (wrong Merchant Token / vendor group, revoked app). Re-authorize from the channel card; the schema pull repeats automatically.
- **Products in the collection but not in the export**: they fail the destination's required fields — run `runPreflight` for the collection + destination and read the required-field groups.
- **Template missing from the export picker**: the template is bound to a different destination; `listTemplates` shows each template's destination.
- **Collection "disappeared"**: it was connected to a channel — look under Trading Partners, and query it by id.

## App screens

- **Trading Partners** (`/org/{orgId}/channel`) — configured channels with type, connection status, connected collections and their counts, export runs.
- **Product → Trading Partner Overrides** — the per-destination product data above.
- **Subscriptions** (`/org/{orgId}/subscriptions`) — notification subscriptions for trading-partner events (feed results, file transmissions).

## Advanced: controlled API reads

No MCP tool lists sub-catalogs or connections directly, so `callApiRead` (reads only) fills in:
- Unconnected collections: GET `org/{orgId}/sub-catalog`. Connected ones (the channel connections): GET `org/{orgId}/sub-catalog/destinations`.
- Channels: GET `org/{orgId}/channel`. Connections and their types: GET `org/{orgId}/connection`, GET `org/{orgId}/connection/types`.
- An override readback: GET `org/{orgId}/product/{productId}` with `query` `{"groupBy":"UPC","destinationId":<dest>}` — the override list is on the UPC-grouped record; the SKU-grouped read returns none.
Rules: the path must include the org segment, query parameters go in `query` not the path, no whitespace in paths. Connect, disconnect, and override edits belong in the app; if `callApiWrite` is ever used, GET the object first, show the exact change, confirm, write, and re-read — and never use it to remove a destination from a collection (that deletes the collection).

## Related

- Channel readiness for products: `runPreflight` / `runImagePreflight` (see `syndic8-pim` and `syndic8-data-audit`).
- Field mappings and valid values per channel: template tools (`listTemplates`, `getFieldMappings`, `getBrandValidValue*`).
- Media slots per destination (Media Mapping): `syndic8-media`.
- Running exports and reading Third-Party Messages: `syndic8-import-export`.

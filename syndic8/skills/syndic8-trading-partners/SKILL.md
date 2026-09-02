---
name: syndic8-trading-partners
description: |
  Syndic8 trading partners (destinations/channels) — how products flow to a retailer, connections (Amazon, Walmart, Shopify, SFTP), collections/sub-catalogs, and troubleshooting connectivity. Use whenever the user mentions trading partners, destinations, channels, connecting a marketplace, Amazon/Walmart/Shopify connection, sub-catalogs, or the Trading Partners screen.
---

# Syndic8 Trading Partners

Trading partners (channels/destinations) are the retailers and marketplaces that receive product data.

## The data-flow chain

**Product → Collection (sub-catalog) → Destination (trading partner) → Template (mapping + transforms) → Export file/API.**

- A **channel** is the trading-partner record (Trading Partners screen, `/org/{orgId}/channel`); `getMarketplaceList` lists the org's configured channels.
- A **collection connected to a destination** is what scopes which products go to that channel. Connecting a collection moves it from the Collections listing to the channel's view — expected, not a loss (its membership stays queryable, e.g. `queryCollectionProducts`).
- The **template** does the field mapping/transforms for that destination's format; templates are destination-scoped and the export picks the right one.
- **Disconnecting is not symmetric with connecting** — removing a channel connection removes the underlying collection record too. Treat connections as things you set up deliberately, not toggles.

## Connection patterns

- **Amazon** — Login-With-Amazon reverse-OAuth. Seller Central needs the Merchant Token (Seller ID); Vendor Central needs Vendor Code(s). Vendor authorization happens at the **vendor-group** level — one authorization covers every vendor code in the group (codes are 5 characters, one per buying relationship, listed under Vendor Central → Settings → Contacts). The channel's schema is retrieved automatically once auth is established.
- **Walmart** — the customer initiates from the Walmart app store by selecting Syndic8 as solution provider.
- **Shopify** — the customer creates a custom app in Shopify admin, grants the Admin API scopes Syndic8 requests, and provides the access token + storefront URL.
- **SFTP** — Syndic8 maintains an SFTP site for file-drop syndication, with transmission notifications.

**Establish connectivity early** — locating admin access and credentials on the retailer side is routinely the longest lead-time item in going live on a channel.

## Verifying a connection

Send something through it and read **Admin → Third-Party Messages** (triage rules in `syndic8-import-export`). Retailer sandboxes are rare, so connection testing usually happens against the live channel: use delisted or zero-inventory test SKUs and be careful with price changes.

## Related

- Channel readiness for products: `runPreflight` / `runImagePreflight` (see `syndic8-pim` and `syndic8-data-audit`).
- Field mappings and valid values per channel: template tools (`listTemplates`, `getFieldMappings`, `getBrandValidValue*`).

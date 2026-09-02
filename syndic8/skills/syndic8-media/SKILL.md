---
name: syndic8-media
description: |
  Manage product media in Syndic8 — image naming conventions, how image matching works (automatch vs manual attach), image tags and angles, per-channel media requirements, and the media MCP tools. Use whenever the user mentions images, media, photos, image upload, image matching, image tags, media gallery, image readiness, or why a product's images aren't showing for a channel.
---

# Syndic8 Media

How product images relate to products and channels in Syndic8, and how to work with them through the MCP server. The in-app experience (bulk upload UI, media gallery) is richer for large media operations — use these tools for queries, targeted uploads, and readiness checks, and point the user to the app's Media Management screen (`/org/{orgId}/image`) for the rest.

## Core model

- Images are matched to products via a **configurable match key** and stored internally at the UPC level. **SKU is the default and most common key** — every UPC-level record carries its SKU identifier, so a SKU-keyed match covers the whole catalog, and a matched image is shared by that colorway's sizes. The match can instead be keyed on other attributes (e.g. Style Number) via the matching rule's `MatchFilter`; a filename only binds when it resolves to a value of the *configured* key.
- An image's **tag** (often called the angle) determines which channel slot it fills at syndication. Tags are an **org-configured vocabulary** (common defaults: `Main`, `front`, `back`, `left`, `right`, `alt01`–`alt09`; some orgs use `Hero`, `Lifestyle`, `Swatch`, …). If a needed tag "can't be selected", the org's Image Tags list needs that value added — it's configuration, not a platform limit.
- **One tag drives slot selection** — a channel slot can't require two tags at once. If a slot needs two dimensions (e.g. hero + language), use a single combined tag like `Hero_English`.
- A channel's media slot names must **exactly equal** the tags on the media rows — a slot named for a tag no product's media carries resolves nothing.

## Filename convention (drives auto-matching)

`{SKU}_{angle}.{ext}` — e.g. `BP-62787_Main.jpg`. SKU first, then the tag. Agree the convention **before** uploading; auto-matching depends on it. Amazon-style alternatives (`{StyleNumber}_{ColorCode}_{AngleLetter}`) are supported via the org's media-matching rule configuration.

## MCP tools

- `queryProductMedia` — what media a product has, with tags and match state. Start here for any "images look wrong" question.
- `uploadProductMedia` — upload an asset; `attachProductMedia` — associate an uploaded asset to a product/SKU (the manual-match path when filename automatch doesn't apply).
- `runImagePreflight` — per-channel image readiness: which products miss required slots, wrong formats, etc. Scope it like `runPreflight` (see the main skill's readiness section).

## Practical rules

- Auto-match works when filenames resolve to the configured match key (default: SKU) and the org's matching rule is configured; separately uploaded assets that don't fit the pattern need explicit attachment (`attachProductMedia`).
- Minimum 3 images per product; 5–8 for most retailers. Video and PDF media are supported and treated like images.
- 20MB per asset; jpg / png (not 16-bit) / gif / tif / webp.
- Re-running an image *import flow* duplicates media rows (inserts, never upserts) — after a mapping fix, dedupe rather than re-running blindly.
- A match count is not visual proof — when it matters, open the gallery and look at the images.

## Related

- Product model + hierarchy (why SKU-level matching): the `syndic8-pim` skill.
- Export naming and channel slot configuration: the template's Media Mapping — see `syndic8-templates` topics in `syndic8-pim`'s reference.
- Bulk uploads, media imports, and gallery curation: the app / in-app copilot.

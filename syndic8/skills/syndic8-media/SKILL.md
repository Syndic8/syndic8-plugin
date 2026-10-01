---
name: syndic8-media
description: |
  Manage product media in Syndic8 — image naming conventions, how image matching works (automatch vs match-by-id), the hero flag, image tags and angles, per-destination Media Mapping, image import flows, org and brand logos, and the media MCP tools. Use whenever the user mentions images, media, photos, image upload, image matching, image tags, media gallery, image readiness, brand logo, or why a product's images aren't showing for a channel.
---

# Syndic8 Media

How product images relate to products and channels in Syndic8, and how to work with them through the MCP server. The in-app experience (bulk upload UI, media gallery, media-import wizard) is richer for large media operations — use the MCP tools for queries, targeted uploads, and readiness checks, and point the user to the app's Media Management screen (`/org/{orgId}/image`) for the rest.

## Core model

- Images are matched to products via a **configurable match key** and stored internally at the UPC level. **SKU is the default and most common key** — every UPC-level record carries its SKU identifier, so a SKU-keyed match covers the whole catalog, and a matched image is shared by that colorway's sizes. The match can instead be keyed on other attributes (e.g. Style Number) via the matching rule's `MatchFilter`; a filename only binds when it resolves to a value of the *configured* key.
- Upload creates the media record; matching associates it to a SKU. Images can also arrive inside product data (URL columns on a product import) or through a dedicated image import flow — matching is mainly for separately uploaded files.
- An image's **tag** (often called the angle) determines which channel slot it fills at syndication. Tags are an **org-configured vocabulary** (common defaults: `Main`, `front`, `back`, `left`, `right`, `alt01`–`alt09`; some orgs use `Hero`, `Lifestyle`, `Swatch`, `WhiteBG`, `SizeGuide`, …). If a needed tag "can't be selected", the org's Image Tags list needs that value added — it's configuration, not a platform limit. Keep it to ≤5 tags per image typically (20 max).
- **One tag drives slot selection** — a channel slot can't require two tags at once. If a slot needs two dimensions (e.g. hero + language), use a single combined tag like `Hero_English`.
- A channel's media slot names must **exactly equal** the tags on the media rows — a slot named for a tag no product's media carries resolves nothing. Renaming slots without re-tagging the media takes a fully matched channel to zero; change tags and slots together.
- **A match count counts rows, not pixels** — it is not proof the right image renders. When it matters, open the gallery and look.

## The hero flag: exactly ONE per product SKU

`hero` is a true/false flag on the asset, separate from the tag vocabulary. It is what the product grid tile, the preflight row thumbnail, and hero-keyed export slots read.
- **0 heroes** → placeholder tile, no preflight thumbnail (the Media tab still renders).
- **>1 heroes** → the app picks an arbitrary hero per product: tiles show the back shot, preflight shows images for some rows and not others.
- Set it on the front/main shot only: the Media Management side panel ("Hero Image" toggle), or the image import's HERO column (true on the main-image row, false on the rest).
- Audit with `queryProductMedia` filtered on `HEROFLAG Is true`, grouped by SKU — the pass condition is exactly one per SKU. Hero is per asset, and an asset matched at the colorway SKU is shared by every size, so "one per SKU" means one flag per colorway front.

## Filename convention (drives auto-matching)

`{SKU}_{angle}.{ext}` — e.g. `BP-62787_Main.jpg`. SKU first, then the tag; spaces in product names become dashes in filenames. Agree the convention **before** uploading; auto-matching depends on it. Amazon-style alternatives (`{StyleNumber}_{ColorCode}_{AngleLetter}`, A=Main, B=Alt1, …) are supported via the org's media-matching rule configuration. Configure the matching rule in the modern **regex** format on the media-import screen (one rule row such as `{SKU}_{tag}.{ext}` plus a sample file); the legacy separator-formula syntax in older customer docs renders blank on that screen and should not be used.

## Matching: automatch vs match-by-id (the decision rule)

- **Automatch** works when filenames resolve to the **configured match key** (default: SKU) and the org's regex matching rule is configured. It is one org-wide action that matches every unmatched image by filename — run it once after an upload batch, never image by image. Set **Multi Match** on when image files are style-level but SKUs are per size, so one asset serves every SKU of the style.
- **Automatch does not bind** when: filenames don't resolve to the configured key (style-named files on a SKU-keyed rule — re-key the rule to Style Number, turn on Multi Match, or fan the files out per SKU); the org's matching rule isn't configured; or the products were created directly through the API rather than imported (see `syndic8-import-export`). Then **match by id**: `attachProductMedia` associates a specific uploaded asset to a specific product/SKU.
- Rule of thumb: automatch for a convention-named batch; `attachProductMedia` for exceptions, one-offs, and anything the convention can't express.
- **After any product reload, re-run automatch** — media does not follow a reload.

## Media Mapping (per-destination export naming and slots)

Each channel template has a **Media Mapping** tab that controls how media leaves for that destination:
- **Slots**: the destination's image positions (e.g. Amazon `MAIN`, `PT01`…) are each bound to one tag value from the org vocabulary — this is where slot names must equal media tags exactly.
- **Export naming convention**: the filename pattern the destination receives, built from product variables such as `${all:UPC}` for UPC-level naming. The destination's `imageFormat` setting is this **naming pattern, not the file type**; a per-trading-partner override exists for orgs that need a different pattern on one channel.
- **Dimensions and format requirements** are destination-level settings and apply to every brand on the channel.
- `runImagePreflight` scoped to a collection + destination reports which products miss a required slot or fail format rules under that mapping.

## Image import flows (loading media via an import)

Media can be loaded as a file of URLs through an Images & Media import flow (see `syndic8-import-export` for flow mechanics). Durable practices:
- **Give `TYPE` a default of `Image`** in the flow's template. Left unmapped and without a default, every row fails with a lookup-type error.
- **Image imports INSERT, never upsert** — re-running an image flow duplicates every media row (two passing runs of a 150-image file leave 300 rows). Since a re-run is the natural recovery gesture after a mapping fix, plan the dedupe before re-running: remove the duplicate rows in Media Management (or delete and reload once the mapping is right).
- **Do not map a thumbnail-path column** — it double-prefixes the stored path and grid thumbnails render as placeholders. Map the main image URL only; thumbnails are derived.
- **Publishing is asynchronous** — a public URL that is not yet reachable immediately after a publish is not a failure; check again before concluding.

## Org and brand logos

- A new org has no logo. Upload the mark through the org/brand logo picker in the app (a logo needs no SKU match — unmatched media still publishes), then confirm the stored URL opens in a browser before relying on it: a logo URL that fails to load is worse than none.
- **In a house of brands, each brand org needs its own mark** — "logo on every org" is not satisfied by the seller org alone. Where storefronts exist, set the logo inside each storefront as well.
- Prefer transparent-background PNGs. Use the URL of the uploaded file or the logo picker's CDN result; a direct link to an image on the brand's own website is often blocked when loaded from another site, even though it opens in a tab.

## Limits and formats

- **20MB** per asset; jpg / png (not 16-bit) / gif / tif / webp. Video and PDF media are supported and treated like images.
- Partner image configurations cap resolution at 5000×5000.
- Minimum 3 images per product; 5–8 for most retailers. A default/placeholder image can be configured for products with no main image.
- **Deletion vs unlink**: Media Management offers both — deleting the asset removes it for every product; unlinking from a SKU only detaches that association. Choose deliberately; for shared (Multi Match) assets, unlink.

## MCP tools

- `queryProductMedia` — what media a product has, with tags, hero flag, and match state. Start here for any "images look wrong" question.
- `uploadProductMedia` — upload an asset; `attachProductMedia` — associate an uploaded asset to a product/SKU (the manual-match path).
- `runImagePreflight` — per-channel image readiness: which products miss required slots, wrong formats, etc. Scope it like `runPreflight` (see `syndic8-pim`'s readiness section).

## Best practices

- Agree the naming convention before uploading; SKU first in every filename.
- Upload a batch, run automatch once, then `queryProductMedia` the exceptions and attach them by id.
- One hero per SKU — audit it after any bulk load or bulk tag change.
- Change slot names and media tags together, never one without the other.
- Metrics are not eyes: match counts and image preflights check presence and format, not that the orientation is right or the product is intact. Before shipping a channel, look at the gallery.

## Advanced: controlled API reads

Where no MCP tool covers a need, `callApiRead` can read (never write) media state: GET `org/{orgId}/image/statistics` returns the org's matched/unmatched counts for a quick health check. Path must include the org segment, query parameters go in `query`, no whitespace in paths. ⚠️ The platform also exposes a **bulk image update route** — never invoke it without an explicit product list; an empty list applies the change to every image in the org. Do hero and tag changes in Media Management or through the import's HERO column instead.

## Related

- Product model + hierarchy (why SKU-level matching): `syndic8-pim`.
- Image import flows, deletion flows, and reload consequences: `syndic8-import-export`.
- Destinations whose slots the Media Mapping feeds: `syndic8-trading-partners`.
- Bulk uploads, media imports, and gallery curation: the app / in-app copilot.

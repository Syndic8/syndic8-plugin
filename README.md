# Syndic8 for Claude

Work with Syndic8 — the product content syndication platform — directly from Claude (claude.ai, Claude Desktop/Cowork, and Claude Code): query and update products, explore templates and field mappings, run preflight readiness checks, manage media and collections, and diagnose imports, exports, and data-audit scores — connected securely to your own Syndic8 account.

## Install

**From the Claude plugin directory** (claude.ai, Desktop, Cowork): open the directory, find **Syndic8**, and install. The Syndic8 MCP connector appears on the plugin's Connectors tab — connect it and sign in with your Syndic8 credentials.

**In Claude Code:**

```
/plugin marketplace add Syndic8/syndic8-plugin
/plugin install syndic8@syndic8-plugin
```

The first time Claude uses a Syndic8 tool you'll be prompted to sign in with your Syndic8 credentials (OAuth). Claude only sees the organizations and data your Syndic8 user can access, and every action runs under your Syndic8 permissions.

**Access:** you need an active Syndic8 account. If you don't have one, contact sales@syndic8.io.

## What you can ask

- "How many of my products are missing a long description?"
- "Show me the field mappings on my Walmart template"
- "Run preflight for my Amazon template and summarize what's blocking"
- "Write a convert rule that uppercases the color and appends the size"
- "Create a collection of all products updated this week"
- "Compare my Walmart US and Walmart CA templates"
- "Why did my data audit grade so badly?"
- "Which products are missing their hero image for Wayfair?"
- "Rewrite these ten titles to fit the channel's length limit, then preview the update"
- "What has to be mapped in a product import, and in what order do I load files?"

## What's included

| Skill | Covers |
|---|---|
| `syndic8-pim` | The platform model, products, inventory/pricing/POs, collections, preflight, app navigation |
| `syndic8-templates` | Export and import templates, field mappings, the convert-rule language, inheritance, valid values, scoring templates |
| `syndic8-content-optimization` | Scoring and rewriting titles, descriptions, bullets and attributes against a channel's requirements |
| `syndic8-media` | Image naming, matching, tags, the hero flag, media mapping, per-channel media readiness |
| `syndic8-import-export` | Import flows, required mappings, SkipEmpty, pricing and deletion loads, verifying loads, exports, Third-Party Messages |
| `syndic8-data-audit` | Data Audit & Verification, diagnosing bad audit scores, reference tables |
| `syndic8-trading-partners` | Channels/destinations, marketplace connections (Amazon, Walmart, Shopify, SFTP), overrides, sub-catalogs |

## Data handling

- The plugin bundles one remote MCP server, `https://mcp.syndic8.io/mcp`, operated by Syndic8. It is the only destination the plugin sends data to.
- Requests carry your Syndic8 OAuth session and the product, template, media, pricing, and order data you ask Claude to read or change. Nothing is sent anywhere else, and the plugin stores no credentials.
- Product changes made through Claude follow your Syndic8 permissions; bulk updates are always previewed before they're applied, and deletions and deactivations require your explicit confirmation.
- The in-app Syndic8 AI copilot remains the richest experience for creating imports, bulk media upload, approvals, and channel-specific content guidance.

## Support

support@syndic8.io · https://www.syndic8.io

© Syndic8, Inc. Licensed under the terms in [LICENSE](LICENSE) — for use by authorized Syndic8 account holders.

# Syndic8 for Claude

Work with Syndic8 — the product content syndication platform — directly from Claude (Claude Code, Claude Desktop/Cowork): query and update products, explore templates and field mappings, run preflight readiness checks, and manage collections — connected securely to your Syndic8 account.

**Access:** this plugin is available to Syndic8 subscribers. Your GitHub account (or organization) must be granted access to this repository by Syndic8 — contact your Syndic8 representative.

## Install

In Claude Code (or a Cowork session):

```
/plugin marketplace add syndic8/syndic8-plugin
/plugin install syndic8@syndic8-plugin
```

The first time Claude uses a Syndic8 tool you'll be prompted to sign in with your Syndic8 credentials (OAuth). Claude only sees data your Syndic8 user can access.

## What you can ask

- "How many of my products are missing a long description?"
- "Show me the field mappings on my Walmart template"
- "Run preflight for my Amazon template and summarize what's blocking"
- "Create a collection of all products updated this week"
- "Compare my Walmart US and Walmart CA templates"
- "Why did my data audit grade so badly?"
- "Which products are missing their hero image for Wayfair?"
- "What has to be mapped in a product import, and in what order do I load files?"

## What's included

| Skill | Covers |
|---|---|
| `syndic8-pim` | The platform model, products, templates, valid values, preflight, collections, inventory/pricing/POs |
| `syndic8-media` | Image naming, matching, tags, per-channel media readiness |
| `syndic8-import-export` | Import flows, required mappings, SkipEmpty, verifying loads, exports, Third-Party Messages |
| `syndic8-data-audit` | Data Audit & Verification, diagnosing bad audit scores, reference tables |
| `syndic8-trading-partners` | Channels/destinations, marketplace connections (Amazon, Walmart, Shopify, SFTP) |

## Notes

- Product changes made through Claude follow your Syndic8 permissions; bulk updates are always previewed before they're applied.
- The in-app Syndic8 AI copilot remains the richest experience for imports, media, approvals, and channel-specific content optimization.
- Support: support@syndic8.io

© Syndic8. All rights reserved. This plugin and its contents are proprietary to Syndic8 and provided solely for use by authorized Syndic8 subscribers.

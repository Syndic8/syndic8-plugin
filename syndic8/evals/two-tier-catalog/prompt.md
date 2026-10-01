---
name: two-tier-catalog
description: Non-apparel catalog with no middle tier — Claude must not force the apparel-shaped hierarchy
tags: [pim, smoke]
runs: 2
max_turns: 4
allowed_tools: [Skill, Read, Glob, Grep]
---

We're a tire distributor loading our catalog into Syndic8. Every tire size is a separate sellable item with its own UPC and nothing groups them except the tire line name. A consultant said we have to model it as style → SKU → UPC like an apparel brand or image matching breaks. Before you look anything up in my account, tell me how we should model this and why.

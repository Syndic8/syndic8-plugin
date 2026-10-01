---
name: convert-rule
description: Writing a convert rule uses the FUNC syntax rather than rewriting catalog data
tags: [templates]
runs: 2
max_turns: 4
allowed_tools: [Skill, Read, Glob, Grep]
---

In my Syndic8 export template I need the "Variant Name" column to be the color in upper case followed by a space and the size, e.g. "NAVY M". The product fields are COLOR and SIZE. What do I put in the mapping? I don't want to change the product data itself.

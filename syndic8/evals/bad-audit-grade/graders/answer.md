---
type: llm
---

PASS if the answer identifies the products' category assignment as the first thing to check (products sitting on a top-level category are scored against a huge field superset, so irrelevant required fields appear), says the fix is reassigning to the granular retailer-synced category rather than filling in irrelevant data, and suggests splitting the failure list into irrelevant-to-the-category vs genuinely missing.
FAIL if it tells the user to populate "batteries required" for faucets or treats it purely as a data-entry problem.

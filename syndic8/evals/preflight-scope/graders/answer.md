---
type: llm
---

PASS if the plan scopes runPreflight to a collection (not the whole catalog in one run), reads the error categories/summary rather than a sample row, runs preflights one at a time, buckets results into required-missing / recommended / invalid values, uses diagnoseField on flagged fields, and reports ready count, blocked count, top failing fields, and suggested fixes.
FAIL if it proposes one whole-catalog run as the answer or reports readiness from a few sample products.

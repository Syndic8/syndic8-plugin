---
type: llm
---

PASS if the answer gives a convert rule in Syndic8's FUNC syntax that upper-cases COLOR and concatenates it with SIZE with a space, placed in the template field's convert rule (mapping), and does not tell the user to edit product data or run a bulk update.
FAIL if it proposes bulk-updating the products, or writes the rule in a different language (Excel formula, SQL, Python) instead of FUNC syntax.

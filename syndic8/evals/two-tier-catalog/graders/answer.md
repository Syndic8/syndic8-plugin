---
type: llm
---

PASS if the answer says a two-tier catalog is legitimate (one SKU per item is correct when nothing sits between the line and the item), tells the user how to test whether a middle tier exists (count items sharing a name/variant pair), and mentions that the variant level is the SKU tier so image matching still works.
FAIL if it tells the user they must force a three-tier style → SKU → UPC model, or if it invents field names not in the skill.

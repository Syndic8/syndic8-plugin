---
type: llm
---

PASS if the answer says: the product line is the style (product name / STYLENUMBER), each tire size is its own SKU because the SKU tier is the variant level, the UPC is the sellable item so SKU and UPC are one-to-one here and that is correct (not a modelling error); and it mentions that line-level images can be shared across the size SKUs (style-level matching with Multi Match) so image matching does not break.
FAIL if it makes the tire line the SKU with the sizes as its UPCs, tells the user they must invent a colorway tier, or invents field names not in the skill.

# Convert-rule function reference

Every template field carries an ordered list of convert rules. Each rule is a string of the form `FUNC:NAME:arguments`; rules run **in order**, the output of one becoming the input of the next. Read a field's rules with `getFieldMappings` or `listTemplateFields`; test how they resolve for real products with `diagnoseField`.

## Variables

| Variable | Means |
|---|---|
| `$D{FIELD}` | a product data field (e.g. `$D{COLOR}`, `$D{MSRP}`) |
| `$F{Field Name}` | another field on the **same template**, after its own converts |
| `$V{Var}` | a system variable (e.g. `$V{ExcelRowNumber}`) or one stored with `SAVEVAR` |
| `$J{json.path}` | a JSON path into a JSON source |
| `$X{xpath}` | an XPath into an XML source |
| `$[n]` | an array index |
| `JSONPATH:$.path` | a standalone JSON extraction rule (e.g. `JSONPATH:$.product.name`) |

Argument separators: a single `:` follows the function name; `::` separates arguments. Spaces inside arguments are **literal** — the field editor may display them as `[space]` chips, but you type an actual space; typing the text `[space]` emits that text into the output.

## String functions

| Function | Syntax | Example | Result |
|---|---|---|---|
| `CONCAT` | `FUNC:CONCAT::text with $D{…} and $F{…}` | `FUNC:CONCAT::$D{BRAND} $D{PRODUCTNAME} - $D{COLOR}` | `Acme Trail Boot - Brown` |
| `CONCATDELIMITER` (join) | `FUNC:CONCATDELIMITER::$D{A};$D{B};$D{C}::delim` | `FUNC:CONCATDELIMITER::$D{BULLET1};$D{BULLET2}::\|` | joins non-empty values, removes empties |
| `CONCATDELIMITER` (split) | `FUNC:CONCATDELIMITER::$D{FIELD}::delim::index` | `FUNC:CONCATDELIMITER::$D{OPTIONS}::,::0` | first comma-separated value |
| `REPLACE` | `FUNC:REPLACE:match::replacement` (regex allowed) | `FUNC:REPLACE:true::Yes` | `true` → `Yes` |
| `BEGIN_REPLACE` | `FUNC:BEGIN_REPLACE:match::replacement` | `FUNC:BEGIN_REPLACE:::SKU-` | prepends `SKU-` (empty match) or replaces a leading match |
| `END_REPLACE` | `FUNC:END_REPLACE:match::replacement` | `FUNC:END_REPLACE::: in` | appends ` in` or replaces a trailing match |
| `SUBSTR` | `FUNC:SUBSTR:start::end` (0-indexed, end exclusive) | `FUNC:SUBSTR:0::80` | first 80 characters |
| `TOUPPER` | `FUNC:TOUPPER:` or `FUNC:TOUPPER:pattern::` | `FUNC:TOUPPER:[ /-]::` | uppercase the letter after each space, slash or hyphen |
| `TOLOWER` | `FUNC:TOLOWER:` | | lowercase |
| `TOPROPER` | `FUNC:TOPROPER:[ /-]::` | | Title Case, word boundaries at the listed characters |
| `REMOVESPECIALCHAR` | `FUNC:REMOVESPECIALCHAR:` | | strips non-alphanumeric characters |
| `REGEX` | `FUNC:REGEX:{expression}` | `FUNC:REGEX:{\d+}` | extracts the first match |
| `FORMAT` | `FUNC:FORMAT::printf-pattern` | `FUNC:FORMAT::%.2f` | `12.5` → `12.50` |
| `COUNTSTRING` | `FUNC:COUNTSTRING::term` | `FUNC:COUNTSTRING::;` | number of occurrences |
| `SHOPIFYHANDLE` | `FUNC:SHOPIFYHANDLE:` | | URL-safe handle (lowercase, hyphenated) |

**Compound values — the transpose pattern.** Chain `END_REPLACE` (or `BEGIN_REPLACE`) then `CONCAT`: first shape the field's own value, then join it with others. Because rules run in order, `$F{}` references to the field pick up the shaped value.

## Math functions

| Function | Syntax | Example | Result |
|---|---|---|---|
| `MATH` | `FUNC:MATH:operator::operand` (`+ - * /`) | `FUNC:MATH:*::2.54` | centimetres from inches |
| `FIELDMATH` | `FUNC:FIELDMATH:operator::literal` | `FUNC:FIELDMATH:+::100` | adds 100 |
| `EXCELFORMULA` | `FUNC:EXCELFORMULA::formula` | `FUNC:EXCELFORMULA::T$V{ExcelRowNumber}+100` | writes an Excel formula into the cell |

★ **`FUNC:MATH` is a no-op on a `String` field.** The value passes through untouched and nothing is logged — the export simply shows the original number. Set the field's data type to `Decimal` or `Integer` and the rule runs. This is the first thing to check when "the multiplier isn't applying", and the reason to copy data type along with any math rule you copy between fields or templates.

## Date functions

| Function | Syntax | Returns |
|---|---|---|
| `CURRENTDATE` / `TODAY` | `FUNC:CURRENTDATE:` / `FUNC:TODAY:` | today's date |
| `TODAYTIME` | `FUNC:TODAYTIME:` | current date and time |
| `MONTH` | `FUNC:MONTH:` | current month label |
| `QUARTER` | `FUNC:QUARTER:` | current quarter |
| `SEMIANNUAL` | `FUNC:SEMIANNUAL:` | current half-year |
| `ANNUAL` | `FUNC:ANNUAL:` | current year |

Date **output patterns use Java `SimpleDateFormat` syntax** — `yyyy-MM-dd`, `MM/dd/yyyy`, `dd MMM yyyy` — set on the field's format. Capitalisation matters (`MM` month, `mm` minutes).

## Conditional functions

| Function | Syntax | Example |
|---|---|---|
| `IF_THEN` | `FUNC:IF_THEN:'condition'::then::else` | `FUNC:IF_THEN:'$D{PACKAGE_HEIGHT_VALUE}' == ''::::IN` |
| `CASE` | `FUNC:CASE:$D{FIELD}:condition::value::` | `FUNC:CASE:$D{PROP_65}:contains Yes::Lead::` |

`IF_THEN` with an empty-test condition: the **then** branch fires when the field is blank. The example above emits nothing when package height is blank and `IN` otherwise — the standard way to emit a unit only when its value is present. Conditions compare strings (`==`, `!=`) or use `contains`. `CASE` is the multi-way switch: repeat `condition::value::` pairs for each branch; no match → empty (add a trailing default branch if you need one).

Typical pattern — derive an item type per category from a distinguishing attribute:

```
FUNC:IF_THEN:'$D{FAUCET_TYPE}' == ''::Showerhead::Faucet
```

## Lookup functions

| Function | Syntax | Use |
|---|---|---|
| `VALIDVALUE` (scoped) | `FUNC:VALIDVALUE::$D{FIELD}::Display Name::COLUMN::CATEGORY` | brand value → channel value for the destination product type `CATEGORY` (e.g. `FUNC:VALIDVALUE::$D{COLOR}::Color::COLOR::HEADPHONES`) |
| `VALIDVALUE` (generic) | `FUNC:VALIDVALUE::$D{FIELD}` | untyped vocabulary only — convert to the scoped form via Template Admin → Actions → Convert VV to Product-Type |
| `REFERENCETABLE` | `FUNC:REFERENCETABLE::TableName;returnField;param=$D{FIELD}` | row lookup in a Reference Table, returning one column; a miss yields an **empty cell with no warning** |
| `GETPRICING` | `FUNC:GETPRICING::PriceType;Currency` | `FUNC:GETPRICING::MSRP;EUR` — pull a price into a field |
| `GETLANGUAGE` | `FUNC:GETLANGUAGE::lang;fallback;flag` | `FUNC:GETLANGUAGE::en;de;true` — localized text with fallback |
| `ISOCOUNTRY` | `FUNC:ISOCOUNTRY::ISOCOUNTRYABBR:COUNTRYNAME` | country name ↔ ISO code |
| `WEIGHT` | `FUNC:WEIGHT::UNIT:$D{WEIGHT_UNIT}:$D{WEIGHT_VALUE}` | weight normalized to the target unit |
| `WHOLESALEDISCOUNT` | `FUNC:WHOLESALEDISCOUNT::$D{WHOLESALECOST}` | discount-derived price |

**Coalescing (first non-empty).** Chain `CONCATDELIMITER` join rules over candidate fields and take index 0 — the empties are removed, so the first populated candidate wins. Useful for "use the marketing title if present, else the product name".

## Image functions

Image functions select media by **tag** (the angle/role assigned in Media Management — see `syndic8-media`).

| Function | Syntax | Returns |
|---|---|---|
| `IMAGE` | `FUNC:IMAGE::tag` | a single image URL |
| `IMAGELIST` | `FUNC:IMAGELIST::tag1;tag2;` | URLs for the listed tags |
| `IMAGELISTPOS` | `FUNC:IMAGELISTPOS::…` | URL at a position in the list |
| `IMAGELISTROW` | `FUNC:IMAGELISTROW::tags` | one URL per output row |
| `IMAGEMULTILIST` | `FUNC:IMAGEMULTILIST::tags;` | public URLs for several tags |
| `IMAGEDEFAULTMULTILIST` | `FUNC:IMAGEDEFAULTMULTILIST::tags;` | the same, secure URLs |
| `IMAGETAGGEDMULTILIST` | `FUNC:IMAGETAGGEDMULTILIST::tags;` | tag-filtered multi-list |
| `IMAGETHUMB` | `FUNC:IMAGETHUMB::tag` | thumbnail URL |
| `IMAGEFIELD` | `FUNC:IMAGEFIELD::CONTENTBLOCKTITLE2` | an image-level attribute |

## Product / size-range functions

Footwear and apparel exports often need size summaries across the style. These read the product's size set; configure them through the field editor's function picker:

`PRODUCTMINSIZE` (smallest size), `PRODUCTRANGESIZE` (size range label), `PRODUCTSIZERANGECOUNT` (count of sizes), `PRODUCTWIDTHRANGESIZE` / `PRODUCTBYWIDTHRANGESIZE` (and the `ROW` variant, one row per width), `GETWIDTHS`.

## Bullets and description assembly

`FUNC:FORMATMARKETING::Mode:Format` assembles marketing copy from the bullet and description fields. The mode word is case-sensitive, exactly as the function picker lists it:

| Mode | Source |
|---|---|
| `Bullets` | the bullet fields (DESCRIPTION2 onward) |
| `Marketing` | the long product description |
| `BulletsMarketing` | both |

Append `:Html` or `:Text` for the output format — e.g. `FUNC:FORMATMARKETING::Bullets:Text`, `FUNC:FORMATMARKETING::Marketing:Html`. `FUNC:PROPDESCRIPTION::Features:$D{FEATURELIST}` labels and emits a feature list.

Do not add hardcoded manipulation (suffixes, rewrites) to description or bullet fields — the in-app copilot optimizes those and the two collide. Channel voice belongs on the product-name field via `CONCAT`.

## Other functions

| Function | Syntax | Use |
|---|---|---|
| `GENERATEVALUE` | `FUNC:GENERATEVALUE:10` | random alphanumeric of the given length |
| `FIELDROLLUP` | `FUNC:FIELDROLLUP::$D{PRODUCTNAME}::$D{COLOR} $D{NRFCOLORCODE}` | roll up values across the items sharing the ROLLUPBY key; ROLLUPBY accepts **only `$D{SKU}` or `$D{PRODUCTNAME}`** |
| `SAVEVAR` | `FUNC:SAVEVAR::Name` | store the current value for later `$V{Name}` use within the run |
| `JAVASCRIPTEVAL` | `FUNC:JAVASCRIPTEVAL::function getValue(){return "$D{FIELD}";}` | custom logic; **only a `getValue()` entry point** is supported |
| `INVENTORYFIELD` | `FUNC:INVENTORYFIELD::BACKINSTOCKFLAG` | pull an inventory attribute |

## XML output functions

For XML destinations, structural helpers populate nested elements: `XMLPARTYINFO::Customer`, `XMLTYPEVALUE::type;ref`, `XMLDIMENSIONINFO::CARTONS`, `XMLSHIPWINDOW`. These belong to the destination's library parent; children rarely need to touch them.

## Reading and debugging a rule chain

1. `getFieldMappings` — see the source field, the ordered rules and the static default together.
2. Check the **data type** when a math or date rule seems ignored (`String` disables math).
3. `diagnoseField` against a product that should change — confirm the rule actually fires rather than inferring from a clean-looking export.
4. For `VALIDVALUE`, confirm the pairing exists for the **template's product type** (`getBrandValidValueCounts`); a scoped rule ignores untyped pairings.
5. For `REFERENCETABLE`, confirm the table name and that the key values exist — a miss is silent.
6. Finish with an export file opened and inspected; a blank column is the only evidence some of these failures leave.

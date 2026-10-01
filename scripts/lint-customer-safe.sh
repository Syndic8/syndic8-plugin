#!/usr/bin/env bash
# Fails if anything shipped in the plugin leaks internal-only material:
# ticket ids, non-production environment names, internal hosts, credentials,
# internal scripts, known internal org/template ids, staff names, or
# measurement/demo language that only makes sense inside Syndic8.
set -euo pipefail
cd "$(dirname "$0")/.."

PATTERN='V2-[0-9]+|MCP-[0-9]+|AI-[0-9]{3}|[Bb]lack\.syndic8|[Gg]reen\.syndic8|infrared|censhare|\bBlack\b|\bGreen env|[Ss]taging|Bearer |Auth0|eyJ[A-Za-z0-9_-]{20,}|sk-ant-|S8Client|s8_browser|demo_builder|\b(8104|8101|8125|8126|8169|8175|8176|2433|2789|2758|2759|2764|1512|2013|2014|8190|8191|8263|6318|6313)\b|\bJoe\b|DiNardo|Layman|\bIvan\b|ai-toolkit|syndic8-ai-toolkit|AI Agents Tracker|\bprospect\b|\bdemo\b|verified (live|on|20)|measured (live|on|20)|traced 20|20[0-9]{2}-[0-9]{2}-[0-9]{2}|Loki|Grafana|Jira'

if grep -rnE --include='*.md' --include='*.json' -- "$PATTERN" syndic8/ README.md; then
  echo
  echo "lint-customer-safe: FAIL — the lines above must not ship to customers." >&2
  exit 1
fi

# Shape checks the directory validator also applies.
test -f LICENSE || { echo "LICENSE missing" >&2; exit 1; }
grep -q '"license"' syndic8/.claude-plugin/plugin.json || { echo "plugin.json has no license field" >&2; exit 1; }
grep -q '"displayName"' syndic8/.claude-plugin/plugin.json || { echo "plugin.json has no displayName" >&2; exit 1; }
if find syndic8 README.md -name '.DS_Store' -o -name 'Thumbs.db' -o -name 'desktop.ini' | grep -q .; then echo "system files present" >&2; exit 1; fi
big=$(find syndic8 -type f -size +256k); [ -z "$big" ] || { echo "files over 256 KiB: $big" >&2; exit 1; }
count=$(find syndic8 -type f | wc -l | tr -d ' '); [ "$count" -le 512 ] || { echo "too many files: $count" >&2; exit 1; }
words=$(awk '/^```/{c=!c;next} !c' README.md | wc -w | tr -d ' '); [ "$words" -ge 40 ] || { echo "README under 40 words" >&2; exit 1; }
for f in syndic8/skills/*/SKILL.md; do
  head -1 "$f" | grep -q '^---$' || { echo "$f: no frontmatter" >&2; exit 1; }
  grep -qE '^name: [a-z0-9][a-z0-9-]*[a-z0-9]$' "$f" || { echo "$f: bad or missing name" >&2; exit 1; }
  grep -q '^description:' "$f" || { echo "$f: missing description" >&2; exit 1; }
done
echo "lint-customer-safe: OK ($count files, README $words words)"

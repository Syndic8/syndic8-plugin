#!/usr/bin/env python3
"""Checks the OpenAI (Codex-layout) manifest against the Claude manifest it shares a plugin with,
and against the OpenAI plugin directory's documented field limits."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLUGIN = ROOT / "syndic8"
errors = []


def load(rel):
    return json.loads((PLUGIN / rel).read_text())


claude = load(".claude-plugin/plugin.json")
openai = load(".codex-plugin/plugin.json")
mcp = load(".mcp.json")

for key in ("name", "version", "license", "repository", "homepage"):
    if claude.get(key) != openai.get(key):
        errors.append(f"{key} differs: claude={claude.get(key)!r} openai={openai.get(key)!r}")

if claude.get("privacyPolicyUrl") != openai["interface"].get("privacyPolicyURL"):
    errors.append("privacy policy URL differs between manifests")
if claude.get("termsOfServiceUrl") != openai["interface"].get("termsOfServiceURL"):
    errors.append("terms of service URL differs between manifests")

if len(mcp.get("mcpServers", {})) != 1:
    errors.append(".mcp.json must declare exactly one server (OpenAI connects only one)")

ui = openai["interface"]
for key, limit in (("displayName", 30), ("shortDescription", 30), ("longDescription", 4000)):
    if not ui.get(key) or len(ui[key]) > limit:
        errors.append(f"interface.{key} missing or over {limit} chars")
for key in ("developerName", "category", "websiteURL", "supportURL", "privacyPolicyURL", "termsOfServiceURL"):
    if not ui.get(key):
        errors.append(f"interface.{key} is required")
for key in ("websiteURL", "supportURL", "privacyPolicyURL", "termsOfServiceURL"):
    if not str(ui.get(key, "")).startswith("https://"):
        errors.append(f"interface.{key} must be https")
prompts = ui.get("defaultPrompt", [])
if len(prompts) > 3 or any(len(p) > 128 for p in prompts):
    errors.append("defaultPrompt: at most 3 prompts of 128 chars")
for key in ("composerIcon", "logo"):
    path = ui.get(key, "")
    if not path.startswith("./") or not (PLUGIN / path).is_file():
        errors.append(f"interface.{key} must be a ./ path to a packaged file")

review = openai.get("extensions", {}).get("com.openai", {}).get("review", {})
cases = review.get("test_cases", {})
positive, negative = cases.get("positive", []), cases.get("negative", [])
if len(positive) != 5 or len(negative) != 3:
    errors.append(f"review needs exactly 5 positive and 3 negative cases (has {len(positive)}/{len(negative)})")
for i, case in enumerate(positive):
    for key in ("description", "prompt", "tools_triggered", "expected_behavior"):
        if not case.get(key):
            errors.append(f"positive case {i + 1} missing {key}")
for i, case in enumerate(negative):
    for key in ("description", "prompt"):
        if not case.get(key):
            errors.append(f"negative case {i + 1} missing {key}")

# Public-directory exclusions.
if (PLUGIN / "hooks").exists() or "hooks" in openai or "hooks" in claude:
    errors.append("lifecycle hooks are not allowed in the public OpenAI directory")
if list(PLUGIN.rglob(".app.json")) or "apps" in openai:
    errors.append("app references (.app.json) cannot be submitted")

if errors:
    print("check-openai-manifest: FAIL", *errors, sep="\n  ", file=sys.stderr)
    sys.exit(1)
print(f"check-openai-manifest: OK (version {openai['version']})")

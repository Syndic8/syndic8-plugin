# Contributing

This repo is the **customer-facing** Syndic8 plugin. Everything under `syndic8/` ships to every customer who installs it from the Claude plugin directory, so the bar is "would we put this in product documentation".

## Where knowledge comes from

Most content is ported from Syndic8's internal toolkit skills. When porting:

- **Bugs don't ship.** A bug is filed in Jira and fixed; the plugin carries only the durable *practice* that avoids the symptom, stated without the bug narrative.
- **No internal identifiers.** No ticket ids, environment names, hostnames other than `app.syndic8.io` / `mcp.syndic8.io`, org or template ids, staff names, measurement dates, or "verified on" language.
- **No REST recipes or scripts.** Customers work through the MCP tools and the app. The generic `callApiRead` tool may be documented for *reads* no dedicated tool covers (org-scoped path, query params in `query`, no whitespace). `callApiWrite` guidance is always read → show the exact change → confirm → write → re-read, and never a bulk route without an explicit product list.
- **No retailer numbers.** Title lengths, bullet counts and image rules are pulled live from the template and the channel guidelines, never hard-coded.
- **One owner per fact.** If two skills would say it, one says it and the other links.

`scripts/lint-customer-safe.sh` is the executable version of these rules and runs in CI on every PR; `claude plugin validate --strict` runs alongside it. A PR that fails either is not reviewed.

## Releasing

- Bump `syndic8/.claude-plugin/plugin.json` `version` on every merged change that alters shipped files — installed copies only update on a version bump.
- Keep `syndic8/.mcp.json` pinned to the production MCP URL that is listed in the Claude connector directory.
- After merging, re-run Validate in the Claude plugin developer portal before submitting the new version.

## Evals

`syndic8/evals/` holds `claude plugin eval` cases guarding the skills' core doctrines. Add a case when you add a doctrine; run the suite before a release:

```
claude plugin eval ./syndic8 --trust-plugin --runs 1 --ablation none
```

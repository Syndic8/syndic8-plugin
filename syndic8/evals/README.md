# Eval suite

Behavioural checks for the skills in this plugin, run with `claude plugin eval` (early access). Each case is a customer-phrased prompt plus graders: a `tool_used` grader proving the right skill fired, and an `llm` or `regex` grader on the answer. Cases are written to be answerable without a live Syndic8 connection, so they exercise the skills' knowledge rather than the MCP server.

```
claude plugin eval ./syndic8 --trust-plugin --runs 1 --ablation none --max-cost-usd 10
```

Add a case per doctrine the skills are meant to carry; delete a case when the doctrine it guards is removed.

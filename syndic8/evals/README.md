# Eval suite

Behavioural checks for the skills in this plugin, run with the Claude Code plugin eval command (early access). Each case is a customer-phrased prompt plus graders: a tool-used grader proving the right skill fired, and an LLM or regex grader on the answer. Cases are written to be answerable without a live Syndic8 connection, so they exercise the skills' knowledge rather than the MCP server.

To run the suite locally, point the plugin eval command at this plugin's folder with the trust flag and a single run per case; the exact invocation is in the repository's CONTRIBUTING file. Results are written under this folder and are git-ignored.

Add a case per doctrine the skills are meant to carry; delete a case when the doctrine it guards is removed.

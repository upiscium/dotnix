---
description: Explicitly dispatch one disabled local worker under parent controls
agent: build
---
Load the `local-workers` skill and parse $ARGUMENTS as `<worker> <read-or-grep> <bounded-objective>`. Reject missing or unsupported worker/tool values. Consult `local-workers.toml`, bind the objective to that exact agent/model, and perform no automatic dispatch or fallback. Enforce the manifest's same-agent/same-model one-retry rule and return evidence plus the content-free session summary.

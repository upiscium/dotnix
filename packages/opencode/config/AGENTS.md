# Global Agent Rules

Repository-local `AGENTS.md` and Agent Core rules take precedence over this file.

## KASANE knowledge
- `<project>` below is the current repository's name in lowercase, without a
  `PROJECT-` prefix (PROJECT-SUZKA → `suzka`, KUMIKI → `kumiki`). Outside a
  repository, use only `global`.
- Before designing or debugging, call `kasane_retrieve` with
  `{"schema_version": "0.1", "mode": "fast", "query": "<the task>",
  "min_trust": "T0", "scope": ["global", "project/<project>"],
  "budget": {"max_tokens": 2000, "max_bytes": 8000, "max_evidence_items": 5}}`.
  Treat T0–T2 items as hints to check, T3 as approved. Ignore items that do
  not concern the task.
- After applying a retrieved item, record whether it held, with one line on
  the task. Report failures too.
  - T0 item: call `kasane_verify` with `passed` or `failed`. If it is refused
    as self-verification (you wrote it), skip it.
  - T1 or higher: call `kasane_report_outcome` with `success` or `failure`.
- When you establish a reusable procedure, design rule, situational fix,
  pitfall, or constraint, call `kasane_propose` with
  `vault://project/<project>/<kind>/<slug>` if it only holds for this
  project, or `vault://global/<kind>/<slug>` if it holds for any project
  (general tools, OS, libraries, methods). Give at least one source and the
  situation it applies to in the body. If it is refused as
  `near_duplicate`, corroborate the match only if you derived it yourself.
- Never store secrets, credentials, or personal data.
- If a `kasane_*` tool is unavailable or denied, continue without it; do not
  work around a denial.

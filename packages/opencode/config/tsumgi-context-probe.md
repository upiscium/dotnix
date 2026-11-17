# TSUMGI #68 — Synthetic input-token probe

This source-only tool runs OpenCode against a short-lived loopback-only fake
ChatCompletions server, returning hard-coded SSE. The **fake receiver never
forwards Chat requests** to a live TSUMGI model or creates durable Jobs.
It does not modify installed Agents, GPU profiles or TSUMGI services.
The provider URL is overridden only in the child process using temporary
XDG data/cache/state directories.

**This is not an egress sandbox.** OpenCode can still make other outbound
requests (for startup, provider metadata, other loaded configuration, etc.).
Run only on a trusted operator host where outbound traffic is already
controlled. Loopback provider configuration is not proof that the whole
OpenCode subprocess is network-isolated.

Only the first **main request containing Tools** and a fixed synthetic user
marker is selected; initial auxiliary requests are excluded. The probe
prints only numeric request/message/Tool byte lengths, counts and flags.
The probe itself does not log raw messages, Tool schemas, HTTP headers,
private model IDs or request bodies. OpenCode **may write temporary
session records containing the synthetic request** inside the isolated
XDG directories; those directories are deleted on exit, not securely
erased from the filesystem. Use only harmless synthetic input on a
trusted operator host.

## Shape-only mode (does not need GPU Worker access)

From a dotnix checkout with the existing OpenCode config installed:

    python3 tools/tsumgi-context-probe.py --agent plan
    python3 tools/tsumgi-context-probe.py --agent tsumgi-short
    python3 tools/tsumgi-context-probe.py --agent tsumgi-qwen
    python3 tools/tsumgi-context-probe.py --agent tsumgi-fast

The probe reads each dedicated `tsumgi-*` Agent's model from
`agents/*.md` and each model's limits from the `tsumgi` provider in
`opencode.json`, so it follows the checked-out config. The input budget
is `limit.context` minus `limit.output`:

| Model | Agent | Input budget |
| --- | --- | ---: |
| `qwen3.6-35b-a3b-short` | `tsumgi-short` | 10,240 |
| `qwen3.6-35b-a3b` | `tsumgi-qwen` | 63,488 |
| `qwen3.6-35b-a3b-fast` | `tsumgi-fast` | 194,560 |

The plan choice is *ephemerally* tested against the 12K Short profile by
default; pass `--model` to try another TSUMGI model. The canonical OpenAI
plan model assignment is never modified. The same harmless fixed
instruction is used throughout.

When no native tokenizer is available the result explicitly shows
native_token_measurement: null, **not zero**. Byte sizes and Tool counts
are not tokenizer counts and cannot prove an input-budget overflow.
The OpenCode exit code is reported rather than hidden.

## Optional exact native tokenizer counting — requires authorized access

The TSUMGI v0.1.3 Worker calls the pinned native llama.cpp endpoint
POST /v1/chat/completions/input_tokens before executing a Chat Job.
This endpoint is **not available on the public TSUMGI Gateway**.
Only perform native counting after existing approved access to the
correct, already-running GPU Worker has been restored. An approved
read-only loopback port-forward may be used; do not create a public
listener or bypass native authentication.

The probe checks the authorized backend GET /v1/models response and
requires **exactly one loaded model** before any tokenizer request.
The native ID is held in memory only, never printed or put on the
command line. Multiple models or an invalid identity cause BLOCKED.
Do not assume the Gateway model alias equals the native alias.

    python3 tools/tsumgi-context-probe.py \
      --agent tsumgi-qwen \
      --native-token-url http://127.0.0.1:LOCAL_PORT/v1/chat/completions/input_tokens \
      --acknowledge-native-target \
      --ablate-tools

Replace LOCAL_PORT with the authorized local forwarding port. The tool
rejects non-loopback, HTTPS, credential-bearing, noncanonical
and unexpected endpoint URLs. Native HTTP redirects are always refused
before following them, and inherited HTTP proxy use is disabled. It does not obtain private tokens,
configure SSH, bypass a protected UDS or copy model weights. If the
native endpoint requires unavailable credentials, report BLOCKED.

The token request is an **explicit projection** of the synthetic
OpenCode main request onto the native token-relevant fields:
messages, tools, tool_choice, max_tokens, temperature, stream and the
automatically resolved native model alias. The public model alias, stream_options and
inert reasoning_effort are omitted. Full input token counts are compared
to the selected model's input budget. Optional --ablate-tools
requests a *second*, counterfactual tokenizer count without both
`tools` and `tool_choice`, to estimate their combined token overhead.
This is not the real Agent execution contract; instructions may still
mention Tools.

These are **not byte-identical gateway Job traces**. Only the pinned
model's tokenizer can substantiate token counts. Matching historical
failed Job shapes remains correlation, not proof of which Agent sent
a past request.

## Earlier measurements on retired models

The 2026-11-05 native counts for Qwen3.8 and Bonsai 2 (6,144-token input
cap) are recorded in dotnix Issue #68. TSUMGI has since retired both
models, so they do not describe the Qwen3.6 profiles above. For that
synthetic request, OpenCode's `plan` main request counted about 7,840
tokens and a dedicated read-only Agent about 1,500. The request shape has
grown since then, so re-measure against the current profiles.

## Acceptance and safety constraints

- Synthetic instruction only: never use real personal, company or
  production prompts.
- Never store or publish HTTP bodies, prompts, Tool JSON, bearer headers,
  native model paths or raw device identifiers.
- No provider fallback, model switching, deployment, profile change,
  GPU config modification, restart or production DB mutation by the probe.
- No outbound-network isolation for OpenCode is claimed. Use existing
  host egress controls; never treat this as a safe untrusted-plugin sandbox.
- Failure errors reveal only a class, never a response body.
- Unit tests exercise a fake local SSE server and fake native tokenizer;
  this does not qualify a real GPU endpoint.

References: dotnix Issue #68 and PR #79.

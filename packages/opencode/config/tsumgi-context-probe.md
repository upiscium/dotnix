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
    python3 tools/tsumgi-context-probe.py --agent tsumgi-qwen
    python3 tools/tsumgi-context-probe.py --agent tsumgi-bonsai

The plan choice is *ephemerally* tested against TSUMGI Qwen; the canonical
OpenAI plan model assignment is never modified. The two dedicated Agents
retain their respective Qwen/Bonsai selections. The same harmless fixed
instruction is used throughout.

When no native tokenizer is available the result explicitly shows
native_token_measurement: null, **not zero**. Byte sizes and Tool counts
are not tokenizer counts and cannot prove a 6,144 input-token overflow.
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
to the published 6,144-token input limit. Optional --ablate-tools
requests a *second*, counterfactual tokenizer count without both
`tools` and `tool_choice`, to estimate their combined token overhead.
This is not the real Agent execution contract; instructions may still
mention Tools.

These are **not byte-identical gateway Job traces**. Only the pinned
model's tokenizer can substantiate token counts. Matching historical
failed Job shapes remains correlation, not proof of which Agent sent
a past request.

## Qwen native tokenizer evidence (2026-11-05 JST)

After authorized Sirius RDC access returned, a separate transient
in-memory probe recreated the same synthetic OpenCode 1.18.35 main
requests on Adam, then counted them on the **already-running pinned
Qwen Runtime**, using its actual local
`/v1/chat/completions/input_tokens` API. The native model identity
was retrieved privately from `/v1/models`. The payload was projected
onto the same token-relevant fields as the tool above. No actual
inference, Gateway Chat/Job, Worker restart, package/config alteration
or model download occurred. This was a **separate one-shot diagnostic**,
not a claim that the present CLI was deployed onto the GPU host.

| Synthetic Qwen main request | Full input tokens | Without `tools` and `tool_choice` | Combined tool-related delta |
| --- | ---: | ---: | ---: |
| OpenAI-oriented `plan` overridden to Qwen | **7,841** | 4,967 | **2,874** |
| Dedicated `tsumgi-qwen` | **1,504** | 253 | 1,251 |

The effective input limit is **6,144 tokens**. Therefore, the
synthetic `plan` request is **1,697 tokens over the limit**, while
the dedicated Qwen request fits with **4,640 tokens of headroom**.
Removing **both** `tools` and `tool_choice` moves the synthetic
`plan` request below the limit. Their **combined** token contribution
is sufficient to trigger rejection **for this synthetic request**;
this does not isolate each field's contribution, identify the Agent
behind historical failed Jobs, or show that Tool removal preserves
the original `plan` workflow.

**Bonsai remains unmeasured.** Deneb's RDC is still offline, and
Spica is experiencing a CUDA initialization/recovery incident
([TSUMGI #229](https://github.com/upiscium/TSUMGI/issues/229)).
Do not use Qwen's measured token numbers as Bonsai tokenizer results.
Keep this CLI and the native measurement path separately qualified.

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

References: dotnix Issue #68 and documentation-only Draft PR #69.

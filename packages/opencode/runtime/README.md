# agent-runtime local inference runtime

These Ubuntu systemd units are the deployment source for the three local
OpenCode workers hosted on `agent-runtime`, CT12009 (`10.12.2.9`). OpenCode
connects directly to this single runtime. The workers deliberately bind only
the CT's private address; no public DNS, reverse-proxy route, agent pool, or
model fallback is configured.

The runtime and model tree is mounted read-only from
`/root/opencode-local-model-eval` into each service namespace at
`/srv/opencode-local`. Services run as the non-login `opencode-local` user and
write caches only below `/var/lib/opencode-local` and
`/var/cache/opencode-local`.

Install or refresh on CT12009:

```sh
useradd --system --home-dir /var/lib/opencode-local --shell /usr/sbin/nologin opencode-local
usermod -a -G video,render opencode-local
install -d -o root -g root -m 0755 /srv/opencode-local
install -d -o opencode-local -g opencode-local -m 0750 /var/lib/opencode-local /var/cache/opencode-local
install -o root -g root -m 0644 systemd/*.service /etc/systemd/system/
install -d -o root -g root -m 0755 /etc/nftables.d
install -o root -g root -m 0644 nftables.d/opencode-local.nft /etc/nftables.d/
```

Before starting any inference service, confirm that the host's authoritative
`/etc/nftables.conf` includes `/etc/nftables.d/*.nft`, then validate, reload,
and inspect the active ruleset:

```sh
grep -F '/etc/nftables.d/*.nft' /etc/nftables.conf
nft --check --file /etc/nftables.conf
systemctl reload nftables
nft list table inet opencode_local
```

The active table must restrict ports `1919`, `8090`, and `8091` to source
`10.12.0.1`. Do not continue if the table or restriction is absent. Only after
that verification may the local inference listeners be enabled and started:

```sh
systemctl daemon-reload
systemctl enable --now \
  opencode-local-quality \
  opencode-local-fast \
  opencode-local-background
```

The shipped nftables file is an additive dedicated table and never flushes the
host ruleset. Add its include without replacing or flushing existing rules.

Verify all three exact model identities before OpenCode use:

```sh
systemctl is-enabled opencode-local-quality opencode-local-fast opencode-local-background
systemctl is-active opencode-local-quality opencode-local-fast opencode-local-background
curl --fail http://10.12.2.9:1919/v1/models
curl --fail http://10.12.2.9:8091/v1/models
curl --fail http://10.12.2.9:8090/v1/models
```

The endpoints have no application authentication. `nftables.conf` therefore
admits these ports only from the current OpenCode host (`10.12.0.1`) and rejects
other source addresses. Update and review that address before deployment on a
different network. Traffic is still plaintext: do not send secrets, add a
public listener, or add a proxy route without authenticated TLS and a separate
security review. FreeToken needs broader socket-family access for its Gloo
worker; the llama.cpp units retain an explicit address-family allowlist.

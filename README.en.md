# ChatGPT Brain — Web ChatGPT as the brain, your local agent as the hands

ChatGPT thinks. Your local agent works.

[简体中文](README.md) · English

This project connects the ChatGPT web app (the Plus/Pro subscription you already
pay for) to local AI coding/office agents: ChatGPT handles understanding, planning,
and **independent review**, while the local agent executes. Everything ChatGPT needs
for planning and review — code, diffs, files — is pulled read-only from your machine
through ChatGPT's official "connector" feature. Your repository is never uploaded,
no OpenAI API key is required, and no API quota is consumed.

Forked from [XiaoDuoYa/codex-with-chatgpt](https://github.com/XiaoDuoYa/codex-with-chatgpt)
(MIT, 5.2k+ stars), this project keeps the upstream's battle-tested local bridge
service (178 tests) intact and adds adapters for three local agents:

| Local agent | Tier | Notes |
| --- | --- | --- |
| **ZCode** | ✅ Fully automated | browser-use drives the built-in browser to exchange messages and poll replies — same experience as the upstream Codex edition. See [skills/zcode](skills/zcode/SKILL.md) |
| **Qoder** | 🔁 Manual relay | Qoder runs the terminal; a human only relays <1 KB status messages. See [skills/qoder](skills/qoder/README.md) |
| **WorkBuddy** | 🔁 Manual relay | For office-style deliverables (documents, spreadsheets). See [skills/workbuddy](skills/workbuddy/README.md) |
| Codex (upstream) | ✅ Fully automated | The original skill is kept as-is. See [skill/](skill/SKILL.md) |

## How it works (dual-plane)

```
            Web ChatGPT (Plus/Pro)
            understand · plan · independent review
             │               ▲
   control   │ <1KB status    │ data plane
   plane     │ messages       │ ChatGPT pulls code/diffs
   (browser  │ [C2C] protocol │ read-only via the official
    automation) ▼              │ connector
            local bridge c2c (127.0.0.1 + OAuth 2.1 + Cloudflare tunnel)
            9 read-only MCP tools — write operations do not exist server-side
             │
            local agent: edit · shell · git · tests
```

Task loop: `INIT` (goal) → `PLAN` (ChatGPT produces a limited, concrete, executable
plan) → execution → `EXECUTED` (metadata only) → ChatGPT **trusts no verbal reports
and pulls the diff itself for independent review** → `PLAN` (next round) / `DONE` /
`BLOCKED`. Full protocol: [docs/protocol.md](docs/protocol.md).

## Quick start (ZCode)

Prerequisites: Node.js ≥ 20, Git; a ChatGPT Plus/Pro subscription.

```bash
git clone https://github.com/quzhiii/agent-with-chatgpt.git && cd agent-with-chatgpt
powershell -ExecutionPolicy Bypass -File install\install-zcode.ps1   # Windows
bash install/install-zcode.sh                                        # macOS / Linux
```

Then:

1. Start a new ZCode session;
2. In **your project directory**, tell ZCode: **“用 chatgpt-brain 完成首次配置”**
   ("set up chatgpt-brain for first use") — it installs any missing dependency
   (cloudflared), starts the bridge, opens the browser and walks you through creating
   the ChatGPT connector (one action at a time for login / 2FA / pairing code);
3. Afterwards, tell your agent: **“使用 chatgpt-brain 完成 XXX”** ("use chatgpt-brain
   to do XXX") to enter the plan–execute–review loop.

Qoder / WorkBuddy onboarding and daily loops are documented in their adapter docs
(you complete a one-time connector setup in the browser; afterwards a human only
relays status messages).

## Security model

- **Read-only by construction**: the MCP server exposes only 9 read-only tools
  (read files, search, git status/diff, execution records). Write/delete/execute
  tools do not exist, so there is nothing for prompt injection to invoke.
- The bridge binds to 127.0.0.1 only; the public internet only sees a Cloudflare
  tunnel; OAuth 2.1 + PKCE + a one-time pairing code (5-minute TTL, 5 attempts).
- realpath path fencing + sensitive-file default-deny + `.c2cignore`; execution
  output passes a local redaction gate (private keys rejected outright, tokens
  masked, output truncated); tokens are stored only as SHA-256 hashes.
- All credentials live in the OS app-state directory, never in the project. See
  [docs/security.md](docs/security.md).

## Acknowledgements & provenance

This project is forked from [XiaoDuoYa/codex-with-chatgpt](https://github.com/XiaoDuoYa/codex-with-chatgpt)
(MIT, 5.2k+ stars) — many thanks to the upstream author and all contributors.

- **From upstream**: the `src/` local bridge service (C2C CLI, read-only MCP, OAuth,
  tunnel) — kept minimally divergent from upstream (product-name strings and similar
  display text); the full divergence list lives in
  [docs/adapter-matrix.md](docs/adapter-matrix.md), and the `upstream` remote
  continuously syncs upstream updates.
- **Added by this project**: adapters for ZCode / Qoder / WorkBuddy ([skills/](skills/)),
  the SkillHub distribution skill ([skills/skillhub](skills/skillhub/SKILL.md)),
  install scripts, and multi-agent documentation.
- The upstream README is archived at [docs/upstream-readme/](docs/upstream-readme/).

## License

[MIT](LICENSE). Same as upstream — this project stays open source and free to use.
Copyright to the `src/` bridge service belongs to the codex-with-chatgpt upstream
authors and contributors; the agent adapters and the SkillHub distribution belong
to this project's contributors.

> Unofficial community project, not affiliated with or endorsed by OpenAI. The
> ChatGPT connector is an official feature; please comply with the applicable
> terms of service.

## Boundaries

| Item | Notes |
| --- | --- |
| Requires ChatGPT Plus/Pro | Connectors are a subscription feature; without a subscription you can still install the bridge (untested without an account) |
| chatgpt.com redesigns | May affect automated locating; adapters rely on DOM snapshots only, and are repaired per the troubleshooting guide when broken |
| No repo upload | ChatGPT pulls read-only through the tunnel; the repo is never uploaded to ChatGPT files/sources |
| Manual relay cadence | Qoder/WorkBuddy relays are human-paced — slower, but the protocol and review independence are not compromised |

# codex-peasant

Minimal Warcraft III Human Peasant voice notifications for Codex on macOS.

This is a native Codex plugin: three lifecycle hooks, one POSIX shell script, and eight bundled voice lines. It has no skill, MCP server, daemon, desktop notification, state, telemetry, or runtime download.

For the Codex CLI, sounds play only in interactive sessions. The plugin automatically stays silent for non-interactive `codex exec` (including the `codex e` alias) and `codex review` runs, even when they are launched from a terminal. This applies to every configured hook in those runs.

To run Codex non-interactively, use `codex exec "your prompt"`. The top-level `-p`/`--profile` option selects a configuration profile; it does not mean “prompt” or “print.” Passing a prompt directly to `codex` still opens the interactive TUI and remains audible.

## Install

Codex Peasant requires macOS and Codex CLI 0.149.1 or newer.

```sh
codex plugin marketplace add detunized/codex-peasant
codex plugin add codex-peasant@codex-peasant
```

Start a new Codex session after installation. Open `/hooks`, review the three bundled handlers, and trust them once. Codex intentionally skips new or changed non-managed hooks until you approve their exact definitions.

## Events

| Codex event | Voice category | Default | Human Peasant pool |
|---|---|---:|---|
| `SessionStart` from startup, resume, or clear | `session_start` | On | Ready1, What1, What2 |
| `Stop` | `task_complete` | On | JobDone, Ready1, Yes1, Yes3, What3 |
| `PermissionRequest` | `permission_required` | On | What1–4 |

Only main-thread `Stop` is configured. The plugin installs no `SubagentStop` handler, so delegated subtask completion stays silent. Prompt submission and compaction are also intentionally silent. Compact-originated `SessionStart` events remain excluded.

The following Claude-style events are intentionally unsupported because Codex has no equivalent stable lifecycle signal:

- Turn or API failure (`task_error`)
- Failed Bash command (`bash_failure`): `PostToolUse` runs after failures, but its stable hook contract has no dedicated portable exit-status field
- MCP elicitation or input request (`input_required`)

Codex hook input does not currently identify the client that launched the session. To distinguish the public interactive and non-interactive CLI forms without reading unstable transcript data, the macOS hook walks its parent processes and recognizes the `exec`, `e`, and `review` subcommands.

## Configure

Each setting accepts `true`, `1`, `yes`, or `on` as enabled. Any other non-empty value disables that event. `CODEX_PEASANT_MUTED` overrides every event when enabled.

| Environment variable | Default |
|---|---:|
| `CODEX_PEASANT_SESSION_START` | `true` |
| `CODEX_PEASANT_TASK_COMPLETE` | `true` |
| `CODEX_PEASANT_PERMISSION_REQUIRED` | `true` |
| `CODEX_PEASANT_MUTED` | `false` |

For the CLI, export settings in the terminal before starting Codex:

```sh
export CODEX_PEASANT_SESSION_START=true
export CODEX_PEASANT_TASK_COMPLETE=true
export CODEX_PEASANT_PERMISSION_REQUIRED=true
export CODEX_PEASANT_MUTED=false
codex
```

For the macOS app, set variables in the per-user launch environment, then quit and reopen Codex:

```sh
launchctl setenv CODEX_PEASANT_SESSION_START true
launchctl setenv CODEX_PEASANT_TASK_COMPLETE true
launchctl setenv CODEX_PEASANT_PERMISSION_REQUIRED true
launchctl setenv CODEX_PEASANT_MUTED false
```

Remove an app setting with `launchctl unsetenv NAME`. You can also open `/hooks` to review, trust, or disable individual handlers without uninstalling the plugin.

## Requirements

- macOS
- Codex CLI 0.149.1 or newer with hooks enabled
- The built-in `/bin/sh`, `/bin/ps`, `/usr/bin/jot`, `/usr/bin/nohup`, and `/usr/bin/afplay` commands

Playback is randomly selected, detached, and silent on errors.

## Development

The plugin lives under `plugins/codex-peasant/`; `.agents/plugins/marketplace.json` exposes it as the `codex-peasant` marketplace.

```sh
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/codex-peasant/.codex-plugin/plugin.json >/dev/null
python3 -m json.tool plugins/codex-peasant/hooks/hooks.json >/dev/null
sh -n plugins/codex-peasant/scripts/play.sh
```

The audio is pinned to `PeonPing/og-packs` commit [`5d1245fe0188c8da775ca8875c32ee7bf8d92c57`](https://github.com/PeonPing/og-packs/tree/5d1245fe0188c8da775ca8875c32ee7bf8d92c57/peasant) and should be checked against that commit’s [`openpeon.json`](https://github.com/PeonPing/og-packs/blob/5d1245fe0188c8da775ca8875c32ee7bf8d92c57/peasant/openpeon.json).

## License

The plugin code is MIT licensed. The bundled voice recordings have separate terms and attribution; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

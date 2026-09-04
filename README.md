# Figma Bridge

Give your AI assistant read **and write** access to Figma Desktop, in one command.

Once installed, your agent works in the file you have open: create and edit nodes, auto-layout, fills and strokes, variables and tokens, components and variants, text styles — plus plugin console logs and screenshots.

## Install

Ask your agent (Claude Code, Cursor, Windsurf, Codex — anything that can run a shell):

> Install the Figma bridge from https://github.com/jlefort/figma-bridge

It follows [AGENTS.md](AGENTS.md). Or do it yourself — **quit Figma Desktop first**:

```bash
git clone https://github.com/jlefort/figma-bridge.git && cd figma-bridge && ./install.sh
```

Then open Figma Desktop → any file → **Plugins → Development → Figma Desktop Bridge**, run it, leave it running. Restart your AI client and ask it `Check Figma status`.

Done. One-time setup: the plugin stays in your Development list and finds the server on its own (WebSocket, ports 9223–9232).

## Requirements

- **Node 18+**
- **Figma Desktop** — the browser version can't run development plugins
- An MCP client: Claude Code, Claude Desktop, Cursor, Windsurf, …

## What the installer does

1. Checks Node and Figma Desktop.
2. `npx -y figma-console-mcp@latest --print-path` — writes the plugin files to `~/.figma-console-mcp/plugin` and prints the manifest path. The server refreshes them on every start, so they never go stale.
3. Registers the `figma-console` MCP server — `claude mcp add` if the Claude CLI is there, otherwise it prints the JSON snippet and config paths.
4. Imports the plugin into Figma Desktop.
5. Prints the one step left: run the plugin.

Safe to re-run — it overwrites neither an existing server entry nor an existing plugin registration.

## Why Figma must be quit

Figma has no API for registering a development plugin, but it keeps that list as plain JSON in its settings file (`~/Library/Application Support/Figma/settings.json`, or `%APPDATA%\Figma\settings.json`) under `localFileExtensions` — three linked entries per plugin: manifest, code, ui. [`lib/register-figma-plugin.mjs`](lib/register-figma-plugin.mjs) appends those three, which is what the menu command does.

Figma rewrites that file as it runs, so an import done behind its back is lost on quit. The script therefore refuses to write while Figma is open, and prints the two manual clicks instead. Same for: settings file missing (launch Figma once), unfamiliar JSON shape (Figma changed the format), plugin already registered.

It backs the file up to `settings.json.figma-bridge-backup-<timestamp>` and writes atomically. `--no-import` skips this step.

## Options

```bash
./install.sh --token figd_xxx    # optional Figma personal access token
./install.sh --scope project     # user (default) | project | local
./install.sh --client manual     # skip the CLI, just print the JSON snippet
./install.sh --no-import         # leave Figma's settings alone, print the 2 clicks
```

For non-standard setups, read by the import script:

```bash
FIGMA_BRIDGE_SETTINGS=/path/to/settings.json   # override the settings file location
FIGMA_BRIDGE_ASSUME_QUIT=1                     # skip the "is Figma running?" guard
```

## Keep it as a Claude Code skill

So `install the Figma bridge` works in later sessions without the URL:

```bash
mkdir -p ~/.claude/skills && cp -R skills/figma-bridge ~/.claude/skills/
```

## The Figma token

Optional. Everything routed through the running plugin works without it — creating and editing nodes, variables, components, console logs, screenshots, reading the open file. You only need a token for REST reads of a file you don't have open. Get one from your Figma account settings ([how](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)), then `./install.sh --token figd_YOUR_TOKEN`.

Keep it out of repos and chat windows. If one leaks, revoke it in Figma and issue a new one.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Check Figma status` reports no transport | The plugin isn't running. Open it in Figma, leave it open. |
| Plugin missing from Plugins → Development | Figma was open during install, so the import was skipped. Quit Figma, re-run `./install.sh`, reopen Figma. |
| Figma tools missing entirely | Restart the AI client. |
| `Could not resolve the plugin manifest` | Run `npx -y figma-console-mcp@latest --print-path` and read the error. |
| Odd behaviour after a package update | Re-import the manifest — Figma caches plugin files app-level. |
| Undo the import | Remove it from Figma's Development list, or restore `settings.json.figma-bridge-backup-*` with Figma quit. |

## Credits

The MCP server and the Desktop Bridge plugin are [**figma-console-mcp** by southleft](https://github.com/southleft/figma-console-mcp), MIT. This repo is only the installer — no upstream code is vendored. See [NOTICE](NOTICE). Installer licensed MIT — see [LICENSE](LICENSE).

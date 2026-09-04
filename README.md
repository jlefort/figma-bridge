# Figma Bridge

Give your AI assistant read **and write** access to Figma Desktop, in one command.

## Install it by asking your agent

Paste this into Claude Code (or Cursor, Windsurf, Codex — anything that can run a shell):

> Install the Figma bridge from https://github.com/jlefort/figma-bridge

The agent clones this repo, runs the installer, and tells you the one thing left to do in Figma: run the plugin. Registering the MCP server *and* importing the plugin into Figma Desktop are both automatic. Instructions for the agent live in [AGENTS.md](AGENTS.md).

## Or do it yourself

**Quit Figma Desktop first** — the installer imports the plugin for you, and Figma overwrites its own settings file while it runs.

```bash
git clone https://github.com/jlefort/figma-bridge.git && cd figma-bridge && ./install.sh
```

Then:

1. Open Figma Desktop → any file → **Plugins → Development → Figma Desktop Bridge** → run it. Leave it running.
2. Restart your AI client, then ask it: `Check Figma status`.

That's it. The plugin finds the server by itself over WebSocket (it scans ports 9223–9232). One-time setup — it stays in your Development plugins list.

If Figma was open when you ran the installer, it says so and prints the two clicks to import by hand (or quit Figma and re-run — everything else is already done).

## Requirements

- **Node 18+** — `node --version`
- **Figma Desktop** — the browser version cannot run development plugins
- An MCP client: Claude Code, Claude Desktop, Cursor, Windsurf, …

## What the installer actually does

1. Checks Node and Figma Desktop.
2. Runs `npx -y figma-console-mcp@latest --print-path`, which writes the bridge plugin files into `~/.figma-console-mcp/plugin` and prints the manifest path. The plugin is refreshed from the package on every server start, so it never goes stale.
3. Registers the `figma-console` MCP server with your client (`claude mcp add` when the Claude CLI is present, otherwise it prints the JSON snippet and the config file paths).
4. Imports the plugin into Figma Desktop — see below.
5. Prints the one step left: run the plugin.

Re-running is safe: neither an existing `figma-console` entry nor an existing plugin registration is overwritten.

### How the automatic import works

Figma has no API or CLI for registering a development plugin, but it keeps that list as plain JSON in its settings file — `~/Library/Application Support/Figma/settings.json` on macOS, `%APPDATA%\Figma\settings.json` on Windows — under `localFileExtensions`, as three linked entries per plugin (manifest, code, ui). [`lib/register-figma-plugin.mjs`](lib/register-figma-plugin.mjs) appends those three, which is exactly what the menu command does.

That file is undocumented, so the script is deliberately cautious. It will **not** write when:

- **Figma is running** — it rewrites the file as it runs and the change would vanish. Quit Figma and re-run.
- the settings file doesn't exist yet — launch Figma once, or import by hand.
- the JSON isn't what it expects — Figma changed the format; import by hand.
- the plugin is already registered — nothing to do.

Before writing it copies the file to `settings.json.figma-bridge-backup-<timestamp>`, then writes atomically (temp file, re-parsed, renamed into place). Every failure prints the exact manual steps instead. Use `--no-import` to skip it entirely.

### Options

```bash
./install.sh --token figd_xxx        # optional Figma personal access token
./install.sh --scope project         # user (default) | project | local
./install.sh --client manual         # skip the CLI, just print the JSON snippet
./install.sh --no-import             # don't touch Figma's settings; print the 2 clicks
```

Escape hatches for a non-standard setup, read by the import script:

```bash
FIGMA_BRIDGE_SETTINGS=/path/to/settings.json   # override the settings file location
FIGMA_BRIDGE_ASSUME_QUIT=1                     # skip the "is Figma running?" guard
```

## Keep it as a Claude Code skill

So that "install the Figma bridge" works in any future session without the repo URL:

```bash
mkdir -p ~/.claude/skills && cp -R skills/figma-bridge ~/.claude/skills/
```

## About the Figma token

**Optional.** Everything that goes through the running plugin — creating frames, editing nodes, reading the file you have open, variables, components, console logs, screenshots — works without a token.

You only need one for Figma REST API calls (reading a file by key that you don't have open). Create one from your Figma account settings — [how to manage personal access tokens](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens) — then:

```bash
./install.sh --token figd_YOUR_TOKEN
```

Keep it out of your repos and out of chat windows. If you ever paste one somewhere public, revoke it in Figma and generate a new one.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Check Figma status` says no transport | The plugin isn't running. Open it in Figma and leave the window open. |
| Plugin missing from Plugins → Development | Figma was open during the install, so the import was skipped. Quit Figma, re-run `./install.sh`, reopen Figma. |
| Tools missing / server not listed | Restart the AI client after installing. |
| `Could not resolve the plugin manifest` | Run `npx -y figma-console-mcp@latest --print-path` and read the error. |
| Behaves oddly after a package update | Re-import the manifest — Figma caches plugin files at the app level. |
| Want to undo the import | Remove the plugin from Figma's Development list, or restore `settings.json.figma-bridge-backup-*` with Figma quit. |

## Credits

The MCP server and the Desktop Bridge plugin are [**figma-console-mcp** by southleft](https://github.com/southleft/figma-console-mcp), MIT licensed. This repository is only the installer and the agent instructions around it — no upstream code is vendored here. See [NOTICE](NOTICE).

Installer licensed MIT — see [LICENSE](LICENSE).

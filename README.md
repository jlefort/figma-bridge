# Figma Bridge

Give your AI assistant read **and write** access to Figma Desktop, in one command.

## Install it by asking your agent

Paste this into Claude Code (or Cursor, Windsurf, Codex — anything that can run a shell):

> Install the Figma bridge from https://github.com/jlefort/figma-bridge

The agent clones this repo, runs the installer, and tells you the two clicks left to do in Figma.
Instructions for the agent live in [AGENTS.md](AGENTS.md).

## Or do it yourself

```bash
git clone https://github.com/jlefort/figma-bridge.git && cd figma-bridge && ./install.sh
```

Then, as the installer tells you:

1. **Figma Desktop → Plugins → Development → Import plugin from manifest…** → pick the `manifest.json` path it printed (`~/.figma-console-mcp/plugin/manifest.json`).
2. Open any Figma file → **Plugins → Development → Figma Desktop Bridge** → run it. Leave it running.
3. Restart your AI client, then ask it: `Check Figma status`.

That's it. The plugin finds the server by itself over WebSocket (it scans ports 9223–9232). One-time setup — the plugin stays in your Development list.

## Requirements

- **Node 18+** — `node --version`
- **Figma Desktop** — the browser version cannot run development plugins
- An MCP client: Claude Code, Claude Desktop, Cursor, Windsurf, …

## What the installer actually does

1. Checks Node and Figma Desktop.
2. Runs `npx -y figma-console-mcp@latest --print-path`, which writes the bridge plugin files into `~/.figma-console-mcp/plugin` and prints the manifest path. The plugin is refreshed from the package on every server start, so it never goes stale.
3. Registers the `figma-console` MCP server with your client (`claude mcp add` when the Claude CLI is present, otherwise it prints the JSON snippet and the config file paths).
4. Prints the manifest path and the remaining manual steps.

Re-running is safe: an existing `figma-console` entry is never overwritten.

### Options

```bash
./install.sh --token figd_xxx        # optional Figma personal access token
./install.sh --scope project         # user (default) | project | local
./install.sh --client manual         # skip the CLI, just print the JSON snippet
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
| Plugin missing from Plugins → Development | Re-import the manifest (step 1). |
| Tools missing / server not listed | Restart the AI client after installing. |
| `Could not resolve the plugin manifest` | Run `npx -y figma-console-mcp@latest --print-path` and read the error. |
| Behaves oddly after a package update | Re-import the manifest — Figma caches plugin files at the app level. |

## Credits

The MCP server and the Desktop Bridge plugin are [**figma-console-mcp** by southleft](https://github.com/southleft/figma-console-mcp), MIT licensed. This repository is only the installer and the agent instructions around it — no upstream code is vendored here. See [NOTICE](NOTICE).

Installer licensed MIT — see [LICENSE](LICENSE).

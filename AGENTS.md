# Instructions for AI agents

The user asked you to install the Figma bridge. Follow these steps in order. Do not improvise a different install path.

## Rules

- **Never ask the user for their Figma token in chat, and never type one yourself.** It is optional. If the user wants REST API access, tell them to re-run `./install.sh --token <their token>` themselves.
- Do not edit the user's MCP config, or Figma's `settings.json`, by hand — `install.sh` does both.
- Do not vendor, copy or edit the plugin files in `~/.figma-console-mcp/plugin`. The MCP server rewrites them on every start.
- Running the plugin inside Figma is a click in the app. You cannot do it for the user. State it and stop.

## 1. Ask the user to quit Figma Desktop

Before anything else:

> Quit Figma Desktop completely (Cmd+Q on macOS, File → Exit on Windows) and tell me when it's closed.

Why: the installer imports the plugin into Figma for you, and Figma rewrites its own settings file while running, which would discard the import. If the user would rather keep Figma open, that's fine — the installer detects it and prints the two clicks to import by hand instead.

Wait for their answer. Don't quit Figma yourself.

## 2. Get the repo

If you already have it locally, `cd` into it. Otherwise:

```bash
git clone --depth 1 https://github.com/jlefort/figma-bridge.git /tmp/figma-bridge
```

## 3. Run the installer

```bash
bash /tmp/figma-bridge/install.sh
```

It is idempotent — safe to re-run. First run may take a minute while npm downloads the package. Allow up to 5 minutes.

Read its output. Section 4 tells you whether the plugin was imported into Figma:

| What it says | What to do |
|---|---|
| `Imported.` / `Already imported` | Go to step 4. |
| `Figma Desktop is open` | Either ask the user to quit Figma and run the installer again, or relay the manual import steps it printed. Their choice — offer both. |
| Anything else | Relay the manual import steps it printed, verbatim, including the exact `manifest.json` path. |

If the installer itself fails earlier:
- `Node 18+ is required` → tell the user to install Node from nodejs.org, then re-run.
- `Could not resolve the plugin manifest` → run `npx -y figma-console-mcp@latest --print-path` and report the actual error.
- `'claude mcp add' failed` → show the user the JSON snippet from the README's "What the installer actually does" section and the config path for their client.

## 4. Tell the user to run the plugin

> Open Figma Desktop, open any file, then **Plugins → Development → Figma Desktop Bridge** and run it. Leave it running — it connects to the server on its own over WebSocket (ports 9223–9232).

One-time setup: the plugin stays in their Development plugins list.

## 5. Have them restart the client

The MCP server was just added to the config, so their AI client needs a restart to load it. If you are that client, say so — you cannot restart yourself.

## 6. Verify

After the restart, with the plugin running, call the `figma_get_status` tool (or ask "Check Figma status"). A healthy result reports an active WebSocket transport and the connected file name. If it reports no transport, the plugin is not running — send the user back to step 4.

## What this gives you afterwards

The `figma-console` MCP server exposes read and write tools over the open Figma file: create/modify nodes, auto-layout, fills and strokes, variables and tokens, components and variants, text styles, plus plugin console logs and screenshots. Write operations require the bridge plugin to be running.

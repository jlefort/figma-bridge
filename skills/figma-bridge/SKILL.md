---
name: figma-bridge
description: Use when the user wants to connect Figma to their AI assistant, install or repair the Figma Desktop Bridge plugin, or when Figma MCP tools report no active connection. Covers installing the figma-console MCP server, importing the plugin into Figma Desktop, and verifying the WebSocket link.
---

# Installing the Figma bridge

Connects Figma Desktop to an MCP client so the agent can read and write the open Figma file.

## Rules

- **Never ask the user for their Figma personal access token in chat, and never type one yourself.** It is optional (only needed for REST API reads of files that aren't open). If they want it, tell them to run `./install.sh --token <token>` themselves.
- Do not hand-edit MCP config files or Figma's `settings.json` — `install.sh` handles both.
- Do not edit the plugin files in `~/.figma-console-mcp/plugin` — the server rewrites them on every start.
- Running the plugin inside Figma is a click in the app. You cannot do it. State it and stop.

## Procedure

1. **Ask the user to quit Figma Desktop completely** (Cmd+Q / File → Exit) and wait for confirmation. The installer imports the plugin for them, and Figma discards external edits to its settings file while running. If they prefer to keep Figma open, that's fine — the installer detects it and falls back to printing the two manual clicks.

2. **Fetch the installer.**
   ```bash
   git clone --depth 1 https://github.com/jlefort/figma-bridge.git /tmp/figma-bridge
   ```

3. **Run it** (idempotent; allow up to 5 minutes on first run).
   ```bash
   bash /tmp/figma-bridge/install.sh
   ```
   It checks Node 18+, materializes the bridge plugin via `npx -y figma-console-mcp@latest --print-path`, registers the `figma-console` MCP server, then registers the plugin in Figma's development plugin list (three JSON entries in Figma's `settings.json`, backed up first).

   Read section 4 of the output:
   - `Imported.` / `Already imported` → continue.
   - `Figma Desktop is open` → offer both: quit Figma and re-run the installer, or import by hand using the printed path.
   - anything else → relay the printed manual steps verbatim, including the exact `manifest.json` path.

4. **Tell the user to run the plugin:** open Figma Desktop → any file → **Plugins → Development → Figma Desktop Bridge** → run it, leave it running. It connects on its own (WebSocket, ports 9223–9232). One-time setup — it persists in their Development plugins list.

5. **Restart the MCP client** so it loads the new server. If you are the client, say so.

6. **Verify** with `figma_get_status` (or "Check Figma status"). Healthy = active WebSocket transport plus the connected file name. No transport = the plugin isn't running; back to step 4.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| No transport in status | Plugin not running in Figma. |
| Plugin absent from Plugins → Development | Figma was open during install, so the import was skipped — quit Figma, re-run `install.sh`, reopen Figma. |
| Figma tools not available at all | Client not restarted after install. |
| `Could not resolve the plugin manifest` | Run `npx -y figma-console-mcp@latest --print-path` and read the real error. |
| Odd behaviour after a package update | Re-import the manifest; Figma caches plugin files app-level. |
| Write tools fail, reads work | Bridge plugin down; or the client is on the read-only remote SSE setup instead of the npx one. |
| Need to undo the import | Remove it from Figma's Development list, or restore `settings.json.figma-bridge-backup-*` with Figma quit. |

## Credit

Upstream server and plugin: [figma-console-mcp by southleft](https://github.com/southleft/figma-console-mcp) (MIT).

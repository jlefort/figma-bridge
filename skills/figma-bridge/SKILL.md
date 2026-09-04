---
name: figma-bridge
description: Use when the user wants to connect Figma to their AI assistant, install or repair the Figma Desktop Bridge plugin, or when Figma MCP tools report no active connection. Covers installing the figma-console MCP server, importing the plugin into Figma Desktop, and verifying the WebSocket link.
---

# Installing the Figma bridge

Connects Figma Desktop to an MCP client so you can read and write the open Figma file.

## Rules

- **Never ask for the user's Figma token, and never type one yourself.** It's optional (REST reads of files that aren't open). If they want it, tell them to run `./install.sh --token <token>` themselves.
- Don't hand-edit MCP configs or Figma's `settings.json` — `install.sh` does both.
- Don't edit the plugin files in `~/.figma-console-mcp/plugin` — the server rewrites them on every start.
- Running the plugin inside Figma is a click in the app. You can't do it. Say so and stop.

## Steps

1. **Have the user quit Figma Desktop** (Cmd+Q / File → Exit) and wait for confirmation. Figma discards outside edits to its settings file while running, which would drop the import. If they'd rather keep it open, the installer detects it and prints the manual clicks instead.

2. **Clone.**
   ```bash
   git clone --depth 1 https://github.com/jlefort/figma-bridge.git /tmp/figma-bridge
   ```

3. **Run it** — idempotent, allow up to 5 minutes on first run.
   ```bash
   bash /tmp/figma-bridge/install.sh
   ```
   It checks Node 18+, writes the plugin via `npx -y figma-console-mcp@latest --print-path`, registers the `figma-console` MCP server, then registers the plugin in Figma's development list (three JSON entries in Figma's `settings.json`, backed up first).

   Section 4 of the output:
   - `Imported.` / `Already imported` → continue.
   - `Figma Desktop is open` → offer both: quit Figma and re-run, or import by hand with the printed path.
   - anything else → relay the printed manual steps verbatim, with the exact `manifest.json` path.

4. **Have them run the plugin:** Figma Desktop → any file → **Plugins → Development → Figma Desktop Bridge** → run, leave running. It connects on its own (WebSocket, ports 9223–9232). One-time — it stays in their Development list.

5. **Have them restart the AI client** so it loads the server. If you are that client, say so.

6. **Verify** with `figma_get_status` (or "Check Figma status"). Healthy = active WebSocket transport plus the connected file name. No transport = plugin not running; back to step 4.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| No transport in status | Plugin not running in Figma. |
| Plugin absent from Plugins → Development | Figma was open during install — quit it, re-run `install.sh`, reopen Figma. |
| Figma tools missing entirely | Client not restarted after install. |
| `Could not resolve the plugin manifest` | Run `npx -y figma-console-mcp@latest --print-path` and read the real error. |
| Odd behaviour after a package update | Re-import the manifest; Figma caches plugin files app-level. |
| Writes fail, reads work | Plugin down, or the client is on the read-only remote SSE setup instead of npx. |
| Undo the import | Remove it from Figma's Development list, or restore `settings.json.figma-bridge-backup-*` with Figma quit. |

## Credit

Upstream server and plugin: [figma-console-mcp by southleft](https://github.com/southleft/figma-console-mcp) (MIT).

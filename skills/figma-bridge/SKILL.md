---
name: figma-bridge
description: Use when the user wants to connect Figma to their AI assistant, install or repair the Figma Desktop Bridge plugin, or when Figma MCP tools report no active connection. Covers installing the figma-console MCP server, importing the plugin manifest in Figma Desktop, and verifying the WebSocket link.
---

# Installing the Figma bridge

Connects Figma Desktop to an MCP client so the agent can read and write the open Figma file.

## Rules

- **Never ask the user for their Figma personal access token in chat, and never type one yourself.** It is optional (only needed for REST API reads of files that aren't open). If they want it, tell them to run `./install.sh --token <token>` themselves.
- Do not hand-edit MCP config files. Do not edit the plugin files in `~/.figma-console-mcp/plugin` — the server rewrites them on every start.
- The Figma-side steps are clicks in the app. You cannot perform them. State them and stop.

## Procedure

1. **Fetch the installer.**
   ```bash
   git clone --depth 1 https://github.com/jlefort/figma-bridge.git /tmp/figma-bridge
   ```

2. **Run it** (idempotent; allow up to 5 minutes on first run).
   ```bash
   bash /tmp/figma-bridge/install.sh
   ```
   It checks Node 18+, materializes the bridge plugin via `npx -y figma-console-mcp@latest --print-path`, registers the `figma-console` MCP server, and prints the absolute path of the `manifest.json` to import.

3. **Tell the user**, with the real path substituted:
   - Figma Desktop → **Plugins → Development → Import plugin from manifest…** → select `<MANIFEST PATH>`
   - Open any Figma file → **Plugins → Development → Figma Desktop Bridge** → run it, leave it running. It connects on its own (WebSocket, ports 9223–9232).

   One-time setup — the plugin persists in their Development plugins list.

4. **Restart the MCP client** so it loads the new server. If you are the client, say so.

5. **Verify** with `figma_get_status` (or "Check Figma status"). Healthy = active WebSocket transport plus the connected file name. No transport = the plugin isn't running; back to step 3.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| No transport in status | Plugin not running in Figma. |
| Plugin absent from Plugins → Development | Manifest never imported, or Figma was reinstalled — re-import. |
| Figma tools not available at all | Client not restarted after install. |
| `Could not resolve the plugin manifest` | Run `npx -y figma-console-mcp@latest --print-path` and read the real error. |
| Odd behaviour after a package update | Re-import the manifest; Figma caches plugin files app-level. |
| Write tools fail, reads work | Bridge plugin down; or the client is on the read-only remote SSE setup instead of the npx one. |

## Credit

Upstream server and plugin: [figma-console-mcp by southleft](https://github.com/southleft/figma-console-mcp) (MIT).

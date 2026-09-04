# Instructions for AI agents

The user asked you to install the Figma bridge. Follow these steps in order.

## Rules

- **Never ask for the user's Figma token, and never type one yourself.** It's optional. If they want REST access, tell them to run `./install.sh --token <token>` themselves.
- Don't hand-edit the MCP config or Figma's `settings.json` — `install.sh` does both.
- Don't edit the plugin files in `~/.figma-console-mcp/plugin` — the server rewrites them on every start.
- Running the plugin inside Figma is a click in the app. You can't do it. Say so and stop.

## 1. Have the user quit Figma Desktop

> Quit Figma Desktop completely (Cmd+Q, or File → Exit) and tell me when it's closed.

Figma discards outside edits to its settings file while running, which would drop the import. Wait for their answer; don't quit Figma yourself. If they'd rather keep it open, fine — the installer detects it and prints the manual clicks.

## 2. Clone

```bash
git clone --depth 1 https://github.com/jlefort/figma-bridge.git /tmp/figma-bridge
```

## 3. Run it

```bash
bash /tmp/figma-bridge/install.sh
```

Idempotent. Allow up to 5 minutes — the first run downloads the npm package.

Read section 4 of the output:

| It says | Do |
|---|---|
| `Imported.` / `Already imported` | Go to step 4. |
| `Figma Desktop is open` | Offer both: quit Figma and re-run, or import by hand with the printed path. |
| anything else | Relay the printed manual steps verbatim, including the exact `manifest.json` path. |

Earlier failures:

| Error | Do |
|---|---|
| `Node 18+ is required` | Have them install Node from nodejs.org, then re-run. |
| `Could not resolve the plugin manifest` | Run `npx -y figma-console-mcp@latest --print-path` and report the real error. |
| `'claude mcp add' failed` | Give them the JSON snippet from the README and the config path for their client. |

## 4. Have them run the plugin

> Open Figma Desktop → any file → **Plugins → Development → Figma Desktop Bridge**, and run it. Leave it running — it connects on its own (WebSocket, ports 9223–9232).

One-time: it stays in their Development plugins list.

## 5. Have them restart the AI client

The server was just added to the config. If you are that client, say so — you can't restart yourself.

## 6. Verify

Call `figma_get_status` (or ask "Check Figma status"). Healthy = active WebSocket transport plus the connected file name. No transport = the plugin isn't running; back to step 4.

## What you get afterwards

`figma-console` exposes read and write tools over the open file: nodes, auto-layout, fills and strokes, variables and tokens, components and variants, text styles, plus plugin console logs and screenshots. Writes need the plugin running.

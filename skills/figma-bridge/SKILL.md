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
- Never quit Figma yourself, and never claim the plugin is installed until the installer says so.

## Step 1 — STOP and ask

Before running anything, ask exactly this and **stop your turn**:

> Is Figma Desktop fully quit? (Cmd+Q on macOS, File → Exit on Windows — closing the window isn't enough.) Tell me when it's closed and I'll install everything.

**Do not run a single command until they answer.** The installer imports the plugin into Figma for them, and Figma overwrites its own settings file while running, which silently discards the import.

They'd rather keep Figma open? Continue anyway, and expect the `Figma Desktop is open` outcome in step 3.

## Step 2 — Clone and run

```bash
git clone --depth 1 https://github.com/jlefort/figma-bridge.git /tmp/figma-bridge
bash /tmp/figma-bridge/install.sh
```

Idempotent. Allow up to 5 minutes on first run. It checks Node 18+, writes the plugin via `npx -y figma-console-mcp@latest --print-path`, registers the `figma-console` MCP server, then registers the plugin in Figma's development list (three JSON entries in Figma's `settings.json`, backed up first).

## Step 3 — Read section 4 of the output

| It says | What you do |
|---|---|
| `Imported.` or `Already imported` | Step 4. |
| `Figma Desktop is open` | **Stop and wait for a green light.** Say: "Figma is still running, so the import was skipped — everything else is done. Quit it completely (Cmd+Q / File → Exit) and tell me when it's closed." On confirmation, re-run the installer and read section 4 again. If they insist on keeping Figma open, use [Manual import](#manual-import). |
| anything else | [Manual import](#manual-import), and report the reason the installer printed. |

Earlier failures: `Node 18+ is required` → install Node from nodejs.org and re-run. `Could not resolve the plugin manifest` → run `npx -y figma-console-mcp@latest --print-path` and report the real error. `'claude mcp add' failed` → hand over the printed JSON snippet and the client's config path.

## Step 4 — Have them run the plugin

> Figma Desktop → any file → main menu (the Figma logo, top left) → **Plugins → Development → Figma Desktop Bridge** → run it, leave it running. It connects on its own (WebSocket, ports 9223–9232).

One-time — it stays in their Development list.

## Step 5 — Have them restart the AI client

So it loads the new server. If you are that client, say so.

## Step 6 — Verify

`figma_get_status` (or "Check Figma status"). Healthy = active WebSocket transport plus the connected file name. No transport = plugin not running; back to step 4.

## Manual import

Only when the automatic import couldn't run. Give them these three steps, **with the real path pasted in** from the installer's output:

> **1.** In Figma Desktop, open any file. Main menu (the Figma logo, top left) → **Plugins → Development → Import plugin from manifest…**
>
> **2.** A file picker opens. The file is in a hidden folder, so don't hunt for it:
> - **macOS:** press **Cmd+Shift+G**, paste `<MANIFEST PATH>`, press Enter, click **Open**.
> - **Windows:** paste `<MANIFEST PATH>` into the *File name* field, press Enter.
>
> **3.** Main menu → **Plugins → Development → Figma Desktop Bridge** → run it. Leave it running.

Then step 5.

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

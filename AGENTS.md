# Instructions for AI agents

The user asked you to install the Figma bridge. Follow these steps in order.

## Rules

- **Never ask for the user's Figma token, and never type one yourself.** It's optional. If they want REST access, tell them to run `./install.sh --token <token>` themselves.
- Don't hand-edit the MCP config or Figma's `settings.json` — `install.sh` does both.
- Don't edit the plugin files in `~/.figma-console-mcp/plugin` — the server rewrites them on every start.
- Never quit Figma yourself, and never claim the plugin is installed until the installer says so.

## Step 1 — STOP and ask

Before running anything, ask exactly this and **stop your turn**:

> Is Figma Desktop fully quit? (Cmd+Q on macOS, File → Exit on Windows — closing the window isn't enough.) Tell me when it's closed and I'll install everything.

**Do not run a single command until they answer.** The installer imports the plugin into Figma for them, and Figma overwrites its own settings file while running, which silently discards the import. Skipping this stop means the install half-fails and the user has to do it by hand.

- They say it's closed → step 2.
- They'd rather keep Figma open → step 2 anyway, but expect the `Figma Desktop is open` outcome in step 3 and handle it as written there.

## Step 2 — Clone and run

```bash
git clone --depth 1 https://github.com/jlefort/figma-bridge.git /tmp/figma-bridge
bash /tmp/figma-bridge/install.sh
```

Idempotent. Allow up to 5 minutes — the first run downloads the npm package.

## Step 3 — Read section 4 of the output

| It says | What you do |
|---|---|
| `Imported.` or `Already imported` | Step 4. |
| `Figma Desktop is open` | **Stop and wait for a green light.** Say: "Figma is still running, so the import was skipped — everything else is done. Quit it completely (Cmd+Q / File → Exit) and tell me when it's closed." When they confirm, re-run `bash /tmp/figma-bridge/install.sh` and read section 4 again. If they say they want to keep Figma open, go to [Manual import](#manual-import) instead. |
| anything else | Go to [Manual import](#manual-import). Also report the reason the installer printed. |

Failures earlier in the run:

| Error | What you do |
|---|---|
| `Node 18+ is required` | Have them install Node from nodejs.org, then re-run step 2. |
| `Could not resolve the plugin manifest` | Run `npx -y figma-console-mcp@latest --print-path` and report the real error. Nothing else will work until this does. |
| `'claude mcp add' failed` | Give them the JSON snippet the installer printed and the config path for their client, then continue. |

## Step 4 — Have them run the plugin

> Open Figma Desktop → any file → main menu (the Figma logo, top left) → **Plugins → Development → Figma Desktop Bridge**, and run it. Leave it running — it connects on its own.

One-time: it stays in their Development plugins list.

## Step 5 — Have them restart the AI client

The MCP server was just added to the config. If you are that client, say so — you can't restart yourself.

## Step 6 — Verify

Call `figma_get_status` (or ask "Check Figma status"). Healthy = active WebSocket transport plus the connected file name. No transport = the plugin isn't running; back to step 4.

## Manual import

Only when the automatic import couldn't run. Give them these three steps, **with the real path pasted in** — copy it from the installer's output, don't retype it from memory:

> **1.** In Figma Desktop, open any file. Main menu (the Figma logo, top left) → **Plugins → Development → Import plugin from manifest…**
>
> **2.** A file picker opens. The file lives in a hidden folder, so don't hunt for it:
> - **macOS:** press **Cmd+Shift+G**, paste `<MANIFEST PATH>`, press Enter, then click **Open**.
> - **Windows:** paste `<MANIFEST PATH>` into the *File name* field, press Enter.
>
> **3.** Main menu → **Plugins → Development → Figma Desktop Bridge** → run it. Leave it running.

Then step 5.

## What you get afterwards

`figma-console` exposes read and write tools over the open file: nodes, auto-layout, fills and strokes, variables and tokens, components and variants, text styles, plus plugin console logs and screenshots. Writes need the plugin running.

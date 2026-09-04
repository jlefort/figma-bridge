# Instructions for AI agents

The user asked you to install the Figma bridge. Follow these steps in order. Do not improvise a different install path.

## Rules

- **Never ask the user for their Figma token in chat, and never type one yourself.** It is optional. If the user wants REST API access, tell them to re-run `./install.sh --token <their token>` themselves.
- Do not edit the user's MCP config by hand — `install.sh` does it.
- Do not vendor, copy or edit the plugin files in `~/.figma-console-mcp/plugin`. The MCP server rewrites them on every start.
- Steps 3 and 4 below are clicks in the Figma app. You cannot do them for the user. State them plainly and stop.

## 1. Get the repo

If you already have it locally, `cd` into it. Otherwise:

```bash
git clone --depth 1 https://github.com/jlefort/figma-bridge.git /tmp/figma-bridge
```

## 2. Run the installer

```bash
bash /tmp/figma-bridge/install.sh
```

It is idempotent — safe to re-run. First run may take a minute while npm downloads the package. Allow up to 5 minutes.

Read its output. It prints an absolute path to a `manifest.json` (normally `~/.figma-console-mcp/plugin/manifest.json`). You need that exact path for step 3.

If it fails:
- `Node 18+ is required` → tell the user to install Node from nodejs.org, then re-run.
- `Could not resolve the plugin manifest` → run `npx -y figma-console-mcp@latest --print-path` and report the actual error.
- `'claude mcp add' failed` → show the user the JSON snippet from the README's "What the installer actually does" section and the config path for their client.

## 3. Tell the user to import the plugin

Give them these two steps, with the real path substituted in:

1. In **Figma Desktop**: **Plugins → Development → Import plugin from manifest…** and select `<MANIFEST PATH FROM STEP 2>`.
2. Open any Figma file: **Plugins → Development → Figma Desktop Bridge**, and run it. Leave it running — it connects to the server on its own over WebSocket (ports 9223–9232).

Mention that this is one-time: the plugin stays in their Development plugins list.

## 4. Have them restart the client

The MCP server was just added to the config, so their AI client needs a restart to load it. If you are that client, say so — you cannot restart yourself.

## 5. Verify

After the restart, with the plugin running, call the `figma_get_status` tool (or ask "Check Figma status"). A healthy result reports an active WebSocket transport and the connected file name. If it reports no transport, the plugin is not running — send the user back to step 3.2.

## What this gives you afterwards

The `figma-console` MCP server exposes read and write tools over the open Figma file: create/modify nodes, auto-layout, fills and strokes, variables and tokens, components and variants, text styles, plus plugin console logs and screenshots. Write operations require the bridge plugin to be running.

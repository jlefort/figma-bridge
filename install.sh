#!/usr/bin/env bash
#
# Figma Bridge installer.
#
# Registers the figma-console MCP server with your AI client, puts the Figma Desktop
# Bridge plugin on disk, and imports it into Figma Desktop for you. Safe to re-run:
# it never overwrites an existing server entry or an existing plugin registration.
#
# Usage:
#   ./install.sh [--token figd_xxx] [--scope user|project|local]
#                [--client claude|manual] [--no-import]
#
set -uo pipefail

PKG="figma-console-mcp@latest"
SERVER_NAME="figma-console"
TOKEN="${FIGMA_ACCESS_TOKEN:-}"
SCOPE="user"
CLIENT="auto"
IMPORT="yes"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '\n\033[31m✖ %s\033[0m\n' "$1" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --token)   TOKEN="${2:-}"; shift 2 ;;
    --token=*) TOKEN="${1#*=}"; shift ;;
    --scope)   SCOPE="${2:-}"; shift 2 ;;
    --scope=*) SCOPE="${1#*=}"; shift ;;
    --client)  CLIENT="${2:-}"; shift 2 ;;
    --client=*) CLIENT="${1#*=}"; shift ;;
    --no-import) IMPORT="no"; shift ;;
    -h|--help)
      sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

echo
bold "Figma Bridge installer"
echo

# ---------------------------------------------------------------- 1. preflight
bold "1. Checking prerequisites"

command -v node >/dev/null 2>&1 || die "Node.js is required. Install Node 18+ from https://nodejs.org"
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
[ "$NODE_MAJOR" -ge 18 ] 2>/dev/null || die "Node 18+ is required (found $(node --version 2>/dev/null || echo none))."
ok "Node $(node --version)"

command -v npx >/dev/null 2>&1 || die "npx is required (it ships with Node/npm)."
ok "npx available"

case "$(uname -s)" in
  Darwin)
    if [ -d "/Applications/Figma.app" ] || [ -d "$HOME/Applications/Figma.app" ] \
       || [ -d "/Applications/Figma Beta.app" ]; then
      ok "Figma Desktop found"
    else
      warn "Figma Desktop not found in /Applications — the browser version cannot run development plugins."
    fi ;;
  *)
    warn "Make sure Figma Desktop is installed — the browser version cannot run development plugins." ;;
esac

# ------------------------------------------------------- 2. materialize plugin
echo
bold "2. Fetching the Desktop Bridge plugin"
echo "   (first run downloads the package — this can take a minute)"

MANIFEST="$(npx -y "$PKG" --print-path 2>/dev/null | tail -n 1 | tr -d '\r')"
case "$MANIFEST" in
  */manifest.json) : ;;
  *) die "Could not resolve the plugin manifest. Run 'npx -y $PKG --print-path' to see the error." ;;
esac
[ -f "$MANIFEST" ] || die "Expected a manifest at $MANIFEST but the file is missing."
ok "Manifest ready: $MANIFEST"

# --------------------------------------------------------- 3. register the MCP
echo
bold "3. Registering the MCP server"

AUTODETECTED="no"
if [ "$CLIENT" = "auto" ]; then
  AUTODETECTED="yes"
  if command -v claude >/dev/null 2>&1; then CLIENT="claude"; else CLIENT="manual"; fi
fi

if [ "$CLIENT" = "claude" ]; then
  if claude mcp get "$SERVER_NAME" >/dev/null 2>&1; then
    ok "'$SERVER_NAME' is already configured — left untouched."
    if [ -n "$TOKEN" ]; then
      warn "A token was passed but the existing entry was kept. To replace it:"
      echo "      claude mcp remove $SERVER_NAME -s $SCOPE && ./install.sh --token \"\$YOUR_TOKEN\""
    fi
  else
    set -- claude mcp add "$SERVER_NAME" -s "$SCOPE"
    [ -n "$TOKEN" ] && set -- "$@" -e "FIGMA_ACCESS_TOKEN=$TOKEN"
    set -- "$@" -e "ENABLE_MCP_APPS=true" -- npx -y "$PKG"
    if "$@"; then
      ok "Added '$SERVER_NAME' to your Claude Code config (scope: $SCOPE)."
      [ -z "$TOKEN" ] && warn "No Figma token set — optional, see README."
    else
      die "'claude mcp add' failed. Add the server manually (see README)."
    fi
  fi
else
  if [ "$AUTODETECTED" = "yes" ]; then
    warn "No 'claude' CLI found — add this to your MCP client's config file:"
  else
    warn "Add this to your MCP client's config file:"
  fi
  cat <<'JSON'

  {
    "mcpServers": {
      "figma-console": {
        "command": "npx",
        "args": ["-y", "figma-console-mcp@latest"],
        "env": {
          "ENABLE_MCP_APPS": "true"
        }
      }
    }
  }

JSON
  echo "  Config file locations:"
  echo "    Claude Desktop  ~/Library/Application Support/Claude/claude_desktop_config.json"
  echo "    Cursor          ~/.cursor/mcp.json"
  echo "    Windsurf        ~/.codeium/windsurf/mcp_config.json"
  echo "    Claude Code     ~/.claude.json"
  echo
  echo "  To use the Figma REST API too, add \"FIGMA_ACCESS_TOKEN\": \"figd_...\" next to ENABLE_MCP_APPS."
fi

# ------------------------------------------------------ 4. import it into Figma
echo
bold "4. Importing the plugin into Figma Desktop"

manual_import() {
  echo
  echo "   Do this once, by hand — it takes two clicks:"
  echo
  echo "   In Figma Desktop: Plugins → Development → Import plugin from manifest…"
  echo "   and select this file:"
  echo
  printf '      \033[1m%s\033[0m\n' "$MANIFEST"
  echo
  echo "   (On macOS the file picker hides dotted folders: press Cmd+Shift+G and paste"
  echo "    the path above. On Windows, paste it into the file name field.)"
}

REGISTER="$SCRIPT_DIR/lib/register-figma-plugin.mjs"
IMPORTED="no"

if [ "$IMPORT" = "no" ]; then
  warn "Skipped (--no-import)."
  manual_import
elif [ ! -f "$REGISTER" ]; then
  warn "lib/register-figma-plugin.mjs is missing from this checkout."
  manual_import
else
  DETAIL="$(node "$REGISTER" "$MANIFEST" 2>&1)"
  RC=$?
  detail() { [ -n "$DETAIL" ] && printf '%s\n' "$DETAIL" | sed 's/^/      /'; }
  case "$RC" in
    0)
      ok "Imported. It will show up under Plugins → Development next time Figma starts."
      detail
      IMPORTED="yes" ;;
    10)
      ok "Already imported — Figma's plugin list was left untouched."
      IMPORTED="yes" ;;
    20)
      warn "Figma Desktop is open. It rewrites its settings file as it runs, so the import"
      echo "      would be lost. Two ways forward:"
      echo
      echo "      • Quit Figma completely (Cmd+Q / File → Exit — not just the window),"
      echo "        then run this installer again. Everything else is already done."
      echo "      • Or leave Figma open and import by hand:"
      manual_import ;;
    30)
      warn "Could not find Figma Desktop's settings file, so the import was skipped."
      echo "      Launch Figma Desktop once (that creates it) and re-run this installer,"
      echo "      or just import by hand:"
      manual_import ;;
    *)
      warn "The automatic import did not go through. Nothing was broken — if Figma's"
      echo "      settings file was touched at all, a copy sits next to it as"
      echo "      settings.json.figma-bridge-backup-*. Reason:"
      detail
      echo
      echo "      Import by hand instead:"
      manual_import ;;
  esac
fi

# -------------------------------------------------------------- 5. what's left
echo
bold "5. Last step"
echo
if [ "$IMPORTED" = "yes" ]; then
  echo "   Open Figma Desktop (restart it if it was running), then in any file:"
else
  echo "   Once the plugin is imported, in any Figma file:"
fi
echo "   Plugins → Development → Figma Desktop Bridge — and run it."
echo
echo "   Leave it running. It finds the server on its own (WebSocket, ports 9223–9232)."
echo "   Then restart your AI client and ask it: \"Check Figma status\""
echo

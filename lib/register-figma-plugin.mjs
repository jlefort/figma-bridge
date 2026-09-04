#!/usr/bin/env node
//
// Registers a development plugin in Figma Desktop, i.e. does what
// "Plugins → Development → Import plugin from manifest…" does, without the clicks.
//
// Figma stores its development-plugin list as plain JSON in its settings file,
// under `localFileExtensions`: three linked entries per plugin (manifest, code, ui).
// This appends those three entries. Figma must be quit — it rewrites the settings
// file while running and would drop our change.
//
// This touches an undocumented file, so it is deliberately defensive: it backs the
// file up, writes atomically, refuses to guess, and exits with a code telling the
// caller what to say to the user.
//
// Usage:  node register-figma-plugin.mjs /abs/path/to/manifest.json
//
// Exit codes:
//   0  registered
//   10 already registered — nothing to do
//   20 Figma is running — quit it and re-run
//   30 Figma settings file not found (or unsupported platform)
//   40 something unexpected — fall back to the manual import
//
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";

const REGISTERED = 0;
const ALREADY = 10;
const RUNNING = 20;
const NO_SETTINGS = 30;
const UNEXPECTED = 40;

const note = (msg) => process.stderr.write(`${msg}\n`);

function fail(code, msg) {
  note(msg);
  process.exit(code);
}

// ---------------------------------------------------------------- the manifest
const manifestArg = process.argv[2];
if (!manifestArg) fail(UNEXPECTED, "No manifest path given.");

const manifestPath = path.resolve(manifestArg);
if (!fs.existsSync(manifestPath)) fail(UNEXPECTED, `No manifest at ${manifestPath}`);

let manifest;
try {
  manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
} catch (err) {
  fail(UNEXPECTED, `Could not parse ${manifestPath}: ${err.message}`);
}

const pluginDir = path.dirname(manifestPath);
const codePath = path.join(pluginDir, manifest.main ?? "code.js");
const uiEntry = typeof manifest.ui === "string" ? manifest.ui : null;
const uiPath = uiEntry ? path.join(pluginDir, uiEntry) : null;

if (!fs.existsSync(codePath)) fail(UNEXPECTED, `Manifest points at a missing file: ${codePath}`);
if (uiPath && !fs.existsSync(uiPath)) fail(UNEXPECTED, `Manifest points at a missing file: ${uiPath}`);

// ------------------------------------------------------- where Figma keeps them
// Escape hatches, for a non-standard install or for testing against a copy:
//   FIGMA_BRIDGE_SETTINGS     absolute path to Figma's settings.json
//   FIGMA_BRIDGE_ASSUME_QUIT  set to 1 to skip the "is Figma running?" guard
function settingsCandidates() {
  if (process.env.FIGMA_BRIDGE_SETTINGS) return [process.env.FIGMA_BRIDGE_SETTINGS];
  const home = os.homedir();
  if (process.platform === "darwin") {
    return [path.join(home, "Library", "Application Support", "Figma", "settings.json")];
  }
  if (process.platform === "win32") {
    return [process.env.APPDATA, process.env.LOCALAPPDATA]
      .filter(Boolean)
      .map((base) => path.join(base, "Figma", "settings.json"));
  }
  return [];
}

const settingsPath = settingsCandidates().find((p) => fs.existsSync(p));
if (!settingsPath) {
  fail(
    NO_SETTINGS,
    process.platform === "darwin" || process.platform === "win32"
      ? "Figma Desktop's settings file does not exist yet — launch Figma Desktop once, then re-run."
      : `Automatic import is only supported on macOS and Windows (this is ${process.platform}).`,
  );
}

// ------------------------------------------------------------ is Figma running?
// pgrep exits 1 when nothing matches, which execFileSync turns into a throw — so each
// probe gets its own try/catch, and any probe failure counts as "not running".
function probe(cmd, args, test) {
  try {
    return test(String(execFileSync(cmd, args, { stdio: ["ignore", "pipe", "ignore"] })));
  } catch {
    return false;
  }
}

function figmaIsRunning() {
  const nonEmpty = (out) => out.trim().length > 0;
  if (process.platform === "darwin") {
    // -x matches the process name exactly, so the always-on "figma_agent" font helper
    // does not count as Figma being open.
    return (
      probe("pgrep", ["-x", "Figma"], nonEmpty) || probe("pgrep", ["-x", "Figma Beta"], nonEmpty)
    );
  }
  if (process.platform === "win32") {
    return probe("tasklist", ["/FI", "IMAGENAME eq Figma.exe", "/NH"], (out) => /Figma\.exe/i.test(out));
  }
  return false;
}

if (process.env.FIGMA_BRIDGE_ASSUME_QUIT !== "1" && figmaIsRunning()) {
  fail(RUNNING, "Figma Desktop is running — it would overwrite the change on quit.");
}

// ----------------------------------------------------------------- read + patch
let raw;
try {
  raw = fs.readFileSync(settingsPath, "utf8");
} catch (err) {
  fail(UNEXPECTED, `Could not read ${settingsPath}: ${err.message}`);
}

let settings;
try {
  settings = JSON.parse(raw);
} catch (err) {
  fail(UNEXPECTED, `${settingsPath} is not valid JSON (${err.message}) — left untouched.`);
}
if (settings === null || typeof settings !== "object" || Array.isArray(settings)) {
  fail(UNEXPECTED, `Unexpected shape in ${settingsPath} — left untouched.`);
}

if (settings.localFileExtensions === undefined) settings.localFileExtensions = [];
const entries = settings.localFileExtensions;
if (!Array.isArray(entries)) {
  fail(UNEXPECTED, "Figma's plugin list is not an array — its format changed. Left untouched.");
}

const samePath = (a, b) => path.resolve(String(a ?? "")) === path.resolve(String(b ?? ""));
const already = entries.some(
  (e) =>
    e && typeof e === "object" && e.fileMetadata?.type === "manifest" && samePath(e.manifestPath, manifestPath),
);
if (already) {
  note(`Already in Figma's development plugins: ${manifestPath}`);
  process.exit(ALREADY);
}

const maxId = entries.reduce(
  (max, e) => (e && typeof e === "object" && Number.isInteger(e.id) && e.id > max ? e.id : max),
  0,
);
const manifestId = maxId + 1;
const codeId = maxId + 2;
const uiId = maxId + 3;

entries.push({
  id: manifestId,
  manifestPath,
  lastKnownName: typeof manifest.name === "string" ? manifest.name : "Plugin",
  lastKnownPluginId: typeof manifest.id === "string" ? manifest.id : String(manifestId),
  fileMetadata: {
    type: "manifest",
    codeFileId: codeId,
    ...(uiPath ? { uiFileIds: [uiId] } : {}),
  },
  cachedContainsWidget: false,
});
entries.push({
  id: codeId,
  manifestPath: codePath,
  fileMetadata: { type: "code", manifestFileId: manifestId },
});
if (uiPath) {
  entries.push({
    id: uiId,
    manifestPath: uiPath,
    fileMetadata: { type: "ui", manifestFileId: manifestId },
  });
}

// --------------------------------------------------------- back up, write, done
const backupPath = `${settingsPath}.figma-bridge-backup-${Date.now()}`;
try {
  fs.copyFileSync(settingsPath, backupPath);
} catch (err) {
  fail(UNEXPECTED, `Could not back up ${settingsPath} (${err.message}) — nothing written.`);
}

const tmpPath = `${settingsPath}.figma-bridge-tmp-${process.pid}`;
try {
  // Figma writes this file minified on a single line; match it.
  fs.writeFileSync(tmpPath, JSON.stringify(settings));
  JSON.parse(fs.readFileSync(tmpPath, "utf8")); // paranoia: never move a broken file into place
  fs.renameSync(tmpPath, settingsPath);
} catch (err) {
  try {
    fs.rmSync(tmpPath, { force: true });
  } catch {}
  fail(UNEXPECTED, `Could not write ${settingsPath} (${err.message}). Backup: ${backupPath}`);
}

note(`Registered "${manifest.name ?? "plugin"}" in ${settingsPath}`);
note(`Backup of the previous settings: ${backupPath}`);
process.exit(REGISTERED);

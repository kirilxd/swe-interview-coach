#!/usr/bin/env node
// Tiny HTTP server for the sysdesign canvas viewer.
//   GET  /                 -> viewer/canvas.html
//   GET  /api/canvas.json  -> scene file (empty default if missing)
//   POST /api/canvas.json  -> atomic write (tmp + rename), 2 MB cap
// Node stdlib only. Started in the background by scripts/ensure-canvas.sh.
"use strict";

const http = require("http");
const fs = require("fs");
const path = require("path");
const os = require("os");

const PORT = Number(process.env.SWE_INTERVIEW_COACH_PORT || 9999);
const CONFIG_DIR = process.env.SWE_INTERVIEW_COACH_CONFIG_DIR ||
  path.join(os.homedir(), ".config", "swe-interview-coach");
const CANVAS_JSON = path.join(CONFIG_DIR, "canvas.json");
const VIEWER_HTML = path.resolve(__dirname, "..", "viewer", "canvas.html");
const MAX_BODY_BYTES = 2 * 1024 * 1024;
const EMPTY_SCENE = '{"elements":[],"appState":{}}';

function ensureConfig() {
  try { fs.mkdirSync(CONFIG_DIR, { recursive: true }); } catch (_) {}
  try {
    if (fs.statSync(CANVAS_JSON).size === 0) fs.writeFileSync(CANVAS_JSON, EMPTY_SCENE);
  } catch (_) {
    fs.writeFileSync(CANVAS_JSON, EMPTY_SCENE);
  }
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on("data", (c) => {
      size += c.length;
      if (size > MAX_BODY_BYTES) { reject(new Error("body too large")); req.destroy(); return; }
      chunks.push(c);
    });
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });
}

function atomicWrite(filePath, data) {
  const tmp = filePath + ".tmp." + process.pid;
  fs.writeFileSync(tmp, data);
  fs.renameSync(tmp, filePath);
}

function send(res, status, contentType, body) {
  res.writeHead(status, { "Content-Type": contentType, "Cache-Control": "no-store" });
  res.end(body);
}

async function handle(req, res) {
  const url = req.url || "/";
  if (req.method === "GET" && (url === "/" || url === "/index.html")) {
    try { send(res, 200, "text/html; charset=utf-8", fs.readFileSync(VIEWER_HTML)); }
    catch (_) { send(res, 500, "text/plain", "viewer/canvas.html missing"); }
    return;
  }
  if (req.method === "GET" && url === "/api/canvas.json") {
    try { send(res, 200, "application/json", fs.readFileSync(CANVAS_JSON, "utf8") || EMPTY_SCENE); }
    catch (_) { send(res, 200, "application/json", EMPTY_SCENE); }
    return;
  }
  if (req.method === "POST" && url === "/api/canvas.json") {
    let parsed;
    try {
      parsed = JSON.parse(await readBody(req));
      if (!parsed || typeof parsed !== "object" || !Array.isArray(parsed.elements)) {
        throw new Error("scene must be {elements: [], appState: {}}");
      }
      if (!parsed.appState || typeof parsed.appState !== "object" || Array.isArray(parsed.appState)) {
        parsed.appState = {};
      }
    } catch (e) {
      send(res, 400, "text/plain", "bad request: " + (e.message || String(e)));
      return;
    }
    try {
      atomicWrite(CANVAS_JSON, JSON.stringify(parsed));
      send(res, 200, "application/json", '{"ok":true}');
    } catch (_) {
      send(res, 500, "text/plain", "write failed");
    }
    return;
  }
  send(res, 404, "text/plain", "not found");
}

ensureConfig();
const server = http.createServer((req, res) => {
  handle(req, res).catch((e) => {
    try { send(res, 500, "text/plain", "server error: " + (e.message || String(e))); } catch (_) {}
  });
});
server.on("error", (err) => {
  if (err && err.code === "EADDRINUSE") { console.error("canvas-server: port " + PORT + " already in use"); process.exit(2); }
  console.error("canvas-server error:", err); process.exit(1);
});
server.listen(PORT, "127.0.0.1", () => console.log("canvas-server: http://localhost:" + PORT));

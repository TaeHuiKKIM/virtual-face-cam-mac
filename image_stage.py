"""A dependency-free macOS image presenter with a local browser UI."""

from __future__ import annotations

import argparse
import threading
import webbrowser
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse


APP_NAME = "Image Stage"


HTML = r"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Image Stage</title>
  <style>
    :root {
      color-scheme: dark;
      --panel: #17191d;
      --line: #30343a;
      --ink: #f2f4f5;
      --muted: #a8afb7;
      --accent: #2f8f83;
      --danger: #b73a4a;
    }
    * { box-sizing: border-box; }
    html, body { height: 100%; }
    body {
      margin: 0;
      background: #050607;
      color: var(--ink);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      overflow: hidden;
    }
    main {
      height: 100vh;
      display: grid;
      grid-template-columns: 320px 1fr;
    }
    aside {
      background: var(--panel);
      border-right: 1px solid var(--line);
      padding: 18px;
      display: flex;
      flex-direction: column;
      gap: 14px;
      overflow: auto;
    }
    h1 {
      margin: 0;
      font-size: 22px;
      letter-spacing: 0;
    }
    p {
      margin: 6px 0 0;
      color: var(--muted);
      line-height: 1.45;
      font-size: 13px;
    }
    label {
      display: block;
      margin-bottom: 6px;
      color: #d7dcde;
      font-size: 13px;
      font-weight: 650;
    }
    input, select, button {
      width: 100%;
      min-height: 38px;
      border: 1px solid var(--line);
      border-radius: 6px;
      background: #22262b;
      color: var(--ink);
      font: inherit;
      padding: 8px 10px;
    }
    input[type="checkbox"] {
      width: auto;
      min-height: 0;
      margin-right: 8px;
    }
    button {
      cursor: pointer;
      font-weight: 650;
      background: #2a3036;
    }
    button.primary { background: var(--accent); border-color: var(--accent); }
    button.danger { background: var(--danger); border-color: var(--danger); }
    .row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
    }
    .check {
      display: flex;
      align-items: center;
      gap: 6px;
      min-height: 36px;
      color: var(--muted);
      font-size: 13px;
    }
    .stage {
      min-width: 0;
      min-height: 0;
      display: grid;
      grid-template-rows: 1fr auto;
      background: #000;
    }
    .viewport {
      min-width: 0;
      min-height: 0;
      display: grid;
      place-items: center;
      background: #000;
    }
    .viewport img {
      display: none;
      max-width: 100%;
      max-height: 100%;
      width: 100%;
      height: 100%;
      object-fit: contain;
      transform: none;
      user-select: none;
    }
    .viewport.cover img { object-fit: cover; }
    .viewport.mirror img { transform: scaleX(-1); }
    .viewport.loaded img { display: block; }
    .empty {
      width: min(720px, 82%);
      aspect-ratio: 16 / 9;
      border: 1px dashed #4c535b;
      display: grid;
      place-items: center;
      color: #9ca4ad;
      text-align: center;
      padding: 24px;
    }
    .bar {
      border-top: 1px solid #20242a;
      min-height: 54px;
      padding: 12px 16px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      color: #dce2e1;
      background: rgba(10, 12, 14, 0.94);
      font-size: 13px;
    }
    .list {
      color: var(--muted);
      font-size: 13px;
      line-height: 1.5;
      word-break: break-word;
    }
    @media (max-width: 760px) {
      body { overflow: auto; }
      main { min-height: 100vh; height: auto; grid-template-columns: 1fr; }
      aside { border-right: 0; border-bottom: 1px solid var(--line); }
      .stage { height: 68vh; }
    }
  </style>
</head>
<body>
<main>
  <aside>
    <section>
      <h1>Image Stage</h1>
      <p>Display local images or a folder as a fullscreen-friendly slideshow. No OBS or virtual camera driver required.</p>
    </section>

    <section>
      <label for="files">Images</label>
      <input id="files" type="file" accept="image/*" multiple>
    </section>

    <section>
      <label for="folder">Folder</label>
      <input id="folder" type="file" accept="image/*" multiple webkitdirectory>
    </section>

    <section class="row">
      <button id="prev">Previous</button>
      <button id="next">Next</button>
      <button id="play" class="primary">Play</button>
      <button id="stop" class="danger">Stop</button>
    </section>

    <section class="row">
      <div>
        <label for="interval">Seconds</label>
        <input id="interval" type="number" min="0.5" max="120" step="0.5" value="3">
      </div>
      <div>
        <label for="fit">Fit</label>
        <select id="fit">
          <option value="contain">Contain</option>
          <option value="cover">Cover</option>
        </select>
      </div>
    </section>

    <section class="row">
      <button id="fullscreen">Fullscreen</button>
      <button id="blackout">Blackout</button>
    </section>

    <label class="check"><input id="mirror" type="checkbox">Mirror image</label>

    <section>
      <label>Loaded</label>
      <div id="loaded" class="list">No images loaded.</div>
    </section>
  </aside>

  <section class="stage">
    <div id="viewport" class="viewport">
      <div id="empty" class="empty">Select images or a folder to start.</div>
      <img id="image" alt="">
    </div>
    <div class="bar">
      <span id="status">Ready</span>
      <span id="counter">0 / 0</span>
    </div>
  </section>
</main>

<script>
const filesInput = document.getElementById("files");
const folderInput = document.getElementById("folder");
const viewport = document.getElementById("viewport");
const img = document.getElementById("image");
const empty = document.getElementById("empty");
const statusEl = document.getElementById("status");
const counterEl = document.getElementById("counter");
const loadedEl = document.getElementById("loaded");
const intervalEl = document.getElementById("interval");
const fitEl = document.getElementById("fit");
const mirrorEl = document.getElementById("mirror");

let slides = [];
let index = 0;
let timer = null;
let blackout = false;

function setStatus(text) {
  statusEl.textContent = text;
}

function revokeSlides() {
  slides.forEach(slide => URL.revokeObjectURL(slide.url));
}

function loadFiles(fileList, source) {
  const next = Array.from(fileList || [])
    .filter(file => file.type.startsWith("image/"))
    .map(file => ({ name: file.webkitRelativePath || file.name, url: URL.createObjectURL(file) }));

  if (!next.length) {
    setStatus("No supported images found.");
    return;
  }

  revokeSlides();
  slides = next;
  index = 0;
  blackout = false;
  loadedEl.textContent = slides.slice(0, 8).map(slide => slide.name).join(", ") +
    (slides.length > 8 ? `, +${slides.length - 8} more` : "");
  setStatus(`${slides.length} image(s) loaded from ${source}.`);
  show();
}

function show() {
  viewport.classList.toggle("loaded", slides.length > 0 && !blackout);
  empty.style.display = slides.length && !blackout ? "none" : "grid";
  empty.textContent = blackout ? "Blackout" : "Select images or a folder to start.";

  if (slides.length && !blackout) {
    img.src = slides[index].url;
    img.alt = slides[index].name;
    setStatus(slides[index].name);
  }
  counterEl.textContent = slides.length ? `${index + 1} / ${slides.length}` : "0 / 0";
}

function next(delta = 1) {
  if (!slides.length) return;
  index = (index + delta + slides.length) % slides.length;
  blackout = false;
  show();
}

function play() {
  if (!slides.length) {
    setStatus("Load images first.");
    return;
  }
  stop(false);
  const seconds = Math.max(0.5, Number(intervalEl.value) || 3);
  timer = setInterval(() => next(1), seconds * 1000);
  setStatus(`Playing every ${seconds}s.`);
}

function stop(update = true) {
  if (timer) clearInterval(timer);
  timer = null;
  if (update) setStatus(slides[index]?.name || "Stopped");
}

filesInput.addEventListener("change", () => {
  if (filesInput.files.length) folderInput.value = "";
  loadFiles(filesInput.files, "images");
});

folderInput.addEventListener("change", () => {
  if (folderInput.files.length) filesInput.value = "";
  loadFiles(folderInput.files, "folder");
});

document.getElementById("prev").addEventListener("click", () => next(-1));
document.getElementById("next").addEventListener("click", () => next(1));
document.getElementById("play").addEventListener("click", play);
document.getElementById("stop").addEventListener("click", () => stop(true));
document.getElementById("blackout").addEventListener("click", () => {
  blackout = !blackout;
  show();
});
document.getElementById("fullscreen").addEventListener("click", () => {
  const target = document.querySelector(".stage");
  if (!document.fullscreenElement) target.requestFullscreen();
  else document.exitFullscreen();
});
fitEl.addEventListener("change", () => {
  viewport.classList.toggle("cover", fitEl.value === "cover");
});
mirrorEl.addEventListener("change", () => {
  viewport.classList.toggle("mirror", mirrorEl.checked);
});
document.addEventListener("keydown", event => {
  if (event.key === "ArrowRight" || event.key === " ") next(1);
  if (event.key === "ArrowLeft") next(-1);
  if (event.key.toLowerCase() === "f") document.getElementById("fullscreen").click();
  if (event.key.toLowerCase() === "b") document.getElementById("blackout").click();
});
</script>
</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    server_version = "ImageStage/0.1"

    def log_message(self, fmt: str, *args: object) -> None:
        return

    def do_GET(self) -> None:
        if urlparse(self.path).path != "/":
            self.send_error(HTTPStatus.NOT_FOUND)
            return
        body = HTML.encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=APP_NAME)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8770)
    parser.add_argument("--no-open", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    try:
        server = ThreadingHTTPServer((args.host, args.port), Handler)
    except OSError:
        server = ThreadingHTTPServer((args.host, 0), Handler)
    port = server.server_address[1]
    url = f"http://{args.host}:{port}/"
    print(f"{APP_NAME} running at {url}")
    if not args.no_open:
        threading.Timer(0.4, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()

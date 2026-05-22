const CACHE = "today-shell-v4";
const SHELL = [
  "/static/style.css",
  "/static/app.js",
  "/static/manifest.webmanifest",
  "/static/icon.svg",
  "/static/icon-192.png",
  "/static/icon-512.png",
  "/static/icon-maskable-512.png",
];

self.addEventListener("install", (e) => {
  // Wrap URLs in Request objects with credentials so cache.addAll works
  // when the site is gated by HTTP Basic Auth (otherwise fetches 401).
  const reqs = SHELL.map((u) => new Request(u, { credentials: "same-origin" }));
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(reqs)));
  self.skipWaiting();
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;

  const url = new URL(req.url);
  if (url.pathname.startsWith("/static/")) {
    e.respondWith(
      caches.match(req).then((hit) => hit || fetch(req).then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy));
        return res;
      }))
    );
    return;
  }

  // Navigation requests: network-first, fall back to cached shell page if offline
  if (req.mode === "navigate") {
    e.respondWith(
      fetch(req).catch(() =>
        new Response(
          "<!doctype html><meta charset=utf-8><title>Offline</title>" +
          "<style>body{font-family:system-ui;padding:2rem;color:#222;background:#f7f5f0}</style>" +
          "<h1>Offline</h1><p>Reconnect to load today's entries.</p>",
          { headers: { "Content-Type": "text/html" } }
        )
      )
    );
  }
});

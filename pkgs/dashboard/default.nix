# Static service dashboard. Pure HTML/CSS, no backend — built into the Nix
# store and served by an existing nginx as a directory root.
#
# Usage (see hosts/homeserver/services/dashboard.nix):
#   localPkgs.dashboard {
#     title = "firecat53";
#     groups = [
#       { name = "Media"; items = [
#         { label = "Jellyfin"; url = "https://jellyfin.firecat53.me"; icon = "jellyfin.svg"; }
#       ]; }
#     ];
#   }
#
# `icon` is a filename in ./assets (svg/png). Brand logos come from
# dashboard-icons / selfh.st; today.svg + apparatus.svg are local fallbacks.
{
  lib,
  runCommandLocal,
  writeText,
}:
{
  title ? "Home",
  groups,
}:
let
  esc = lib.escapeXML;

  # Optional `badge` renders a small color-coded pill (badge-home/vps/local) in
  # the card's upper-right, always visible regardless of card width.
  card =
    item:
    let
      badge = lib.optionalString (
        item ? badge
      ) ''<span class="badge badge-${item.badge}">${esc item.badge}</span>'';
    in
    ''
      <a class="card" href="${item.url}" target="_blank" rel="noopener">
        <img class="icon" src="icons/${item.icon}" alt="" loading="lazy" />
        <span class="label">${esc item.label}</span>${badge}
      </a>'';

  section = g: ''
      <section class="group">
        <h2>${esc g.name}</h2>
        <div class="cards">
    ${lib.concatMapStringsSep "\n" card g.items}
        </div>
      </section>'';

  index = writeText "index.html" ''
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>${esc title}</title>
        <link rel="stylesheet" href="style.css" />
      </head>
      <body>
        <main>
    ${lib.concatMapStringsSep "\n" section groups}
        </main>
      </body>
    </html>
  '';

  # Palette + card/link styling mirror the personal home page at firecat53.com
  # (~/.local/srv/http/index.html): slate background, #60a5fa hover accent.
  style = writeText "style.css" ''
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen,
        Ubuntu, Cantarell, sans-serif;
      min-height: 100vh;
      padding: 2.5rem 1.5rem 4rem;
      background: #0f172a;
      color: #e2e8f0;
    }
    main {
      max-width: 1080px;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      gap: 2rem;
    }
    .group h2 {
      margin-bottom: 0.85rem;
      font-size: 0.8rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: #94a3b8;
    }
    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(170px, 1fr));
      gap: 0.75rem;
    }
    .card {
      position: relative;
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1.25rem;
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 8px;
      color: #e2e8f0;
      text-decoration: none;
      font-size: 0.95rem;
      transition: background 0.15s, border-color 0.15s;
    }
    .card:hover {
      background: #1a2744;
      border-color: #60a5fa;
    }
    .icon {
      width: 24px;
      height: 24px;
      flex-shrink: 0;
      object-fit: contain;
    }
    .label {
      flex: 1 1 auto;
      min-width: 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    /* Raised out of the text flow into the upper-right corner so the label can
       use the full card width. */
    .badge {
      position: absolute;
      top: -7px;
      right: 8px;
      font-size: 0.58rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      line-height: 1.5;
      padding: 0.06rem 0.45rem;
      border-radius: 999px;
      background: #0f172a;
      border: 1px solid;
    }
    .badge-home { color: #34d399; border-color: rgba(52, 211, 153, 0.5); }
    .badge-vps { color: #60a5fa; border-color: rgba(96, 165, 250, 0.5); }
    .badge-local { color: #fbbf24; border-color: rgba(251, 191, 36, 0.5); }
  '';
in
runCommandLocal "dashboard" { } ''
  mkdir -p $out/icons
  cp -t $out/icons ${./assets}/*
  cp ${index} $out/index.html
  cp ${style} $out/style.css
''

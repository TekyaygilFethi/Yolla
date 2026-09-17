<p align="center"><img src="src/Yolla/wwwroot/icon-192.png" width="88" alt=""></p>
<h1 align="center">Yolla</h1>
<p align="center">Send photos, videos and files from your phone to a folder on your own computer.<br>Nothing to install on the phone, no cloud, no account.</p>

<p align="center">
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt=".NET 10" src="https://img.shields.io/badge/.NET-10-512BD4">
  <img alt="Docker amd64 | arm64" src="https://img.shields.io/badge/docker-amd64%20%7C%20arm64-2496ED">
  <a href="README.tr.md"><img alt="Türkçe" src="https://img.shields.io/badge/README-T%C3%BCrk%C3%A7e-red"></a>
</p>

<p align="center"><img src="docs/demo.gif" width="300" alt="Yolla on an iPhone: pick 13 photos, watch them land on the PC">&nbsp;&nbsp;<img src="docs/receive-dark.png" width="300" alt="Receive tab in dark mode"></p>

## What is this

Yolla is a small web page that receives files. You run it on the computer that should get the files (a Windows PC, a Mac, a Linux box, a NAS, a Raspberry Pi), open its address on your phone, tap **Photos & Videos**, pick as many as you want, and they show up in a normal folder on that computer. It works the other way too: drop files into the Outbox folder on the computer and pick them up on the phone. Put a tunnel or your own domain in front of it and it works from anywhere, not only at home.

I wrote it because getting a few hundred holiday photos from an iPhone onto a Windows PC is still a chore. iCloud for Windows breaks in creative ways, AirDrop only talks to Apple, and every transfer app wants to be installed on both devices and sit on the same Wi‑Fi. I wanted the opposite: one container, one page, my folder. The whole thing is one C# file and one HTML file with no dependencies, so you can read it in an evening and forget about it afterwards.

## Why Yolla

There are a lot of ways to move files. This is what's different here:

- **Nothing on the phone.** You open a web address. iPhone, Android, your partner's phone, a friend's laptop, whatever has a browser.
- **Nothing to learn.** One page, two buttons. No account, no library, no settings screen, no config file.
- **Files go into a folder.** A normal folder on your own computer. Not a cloud, not some app's private database. Open it in Explorer or Finder like any other.
- **Works from anywhere.** With a free tunnel the same address works from the office, a hotel, another country.
- **Built for big batches.** Select 400 photos and put the phone down. If the connection drops, select them again; it carries on from where it stopped and never uploads the same photo twice.
- **Your uploads can't be read back.** The only folder the phone can see is the Outbox you fill on purpose. Everything you upload is write-only, so someone who finds the link can't browse your photos, and a token stops them uploading, too.
- **Small enough to actually read.** Two files, no dependencies, no telemetry, no calls to anything outside your network.
- **Free.** MIT licence. One-line install on Windows, macOS and Linux; runs fine on a Pi or a NAS.

How it compares with the tools people usually reach for:

| | Yolla | LocalSend | PairDrop | copyparty | Immich / Nextcloud |
|---|:-:|:-:|:-:|:-:|:-:|
| Nothing to install on the phone | ✅ | ❌ app on both devices | ✅ | ✅ | ❌ app |
| Works away from home | ✅ | ❌ same Wi‑Fi only | ~ both pages must be open | ✅ | ✅ |
| Files land in a normal folder | ✅ | ✅ | ~ browser downloads, as ZIP | ✅ | ❌ its own library |
| Nothing to learn or configure | ✅ | ✅ | ✅ | ❌ hundreds of options | ❌ |
| Resumes a broken 400‑file batch | ✅ | ❌ | ❌ | ✅ | ✅ |
| Uploads can't be read back | ✅ | – | – | ~ optional | ❌ |

<sub>As of September 2026, to the best of my knowledge. If I got something wrong about your favourite tool, open an issue and I'll fix the table.</sub>

When you should use something else: if you also want to browse and download your files from the phone, with thumbnails, WebDAV and a media player, [copyparty](https://github.com/9001/copyparty) does all of that and much more. If you want a real photo library with face recognition and automatic backup from the phone, that's [Immich](https://immich.app). If both devices are always on the same Wi‑Fi and installing an app is no problem, [LocalSend](https://localsend.org) is great. Yolla is for when you want exactly one thing: get these files onto my computer, now, without setting anything up.

## What it does

- Uploads three files at a time with retries, and shows progress, speed and time left.
- Streams every file to disk in 32 MB pieces. A dropped connection costs you at most one piece; re-select the same files and it resumes from the exact byte.
- Never overwrites. Same name and same size is skipped as a duplicate; same name but a different file becomes `IMG_0001 (1).JPG`.
- Keeps the photo's date as the file date, so the folder sorts by when the photo was taken. Optional `YYYY/YYYY-MM/` subfolders.
- **Receive** tab: put files in the `Outbox` folder on the computer and they appear on the phone. Download one, several as a ZIP, or on iPhone tap *Save to Photos* and they go straight into the gallery.
- Works in any browser. Drag & drop and paste on desktop. A second button takes non-media files. Light and dark theme, English and Turkish. On iPhone, *Add to Home Screen* gives you an app icon.
- Optional access token, optional size cap, optional subfolder per batch.
- Runs behind Cloudflare Tunnel, ngrok, your own reverse proxy (even under a sub-path) or plain LAN. Chunks stay under Cloudflare's 100 MB request limit.

## Install

### Three things to decide first

The installer doesn't ask questions. It uses defaults, and you can change anything later by running it again. It's still worth knowing what it sets up:

1. **Folder.** Where uploads go on this computer. Default is `Pictures/Yolla` in your home folder. Any folder works; it gets created if it doesn't exist.
2. **Access token.** A password. The phone asks for it once and remembers it. Without a token, anyone who finds the URL can put files on your disk, so keep one unless Yolla never leaves your Wi‑Fi. If you don't pick one, the installer generates a random one and shows it.
3. **Tunnel.** Only needed to reach Yolla from outside your Wi‑Fi. `quick` gives you a random Cloudflare URL with no account (it changes on every restart). `cloudflare` (a permanent URL on your own domain) and `ngrok` need a token from those services, see [Reach it from anywhere](#reach-it-from-anywhere). Skip it while you're trying things out at home.

You need Docker: [Docker Desktop](https://docker.com/products/docker-desktop) on Windows and macOS. On Linux the installer can install it for you (it asks first).

### One line

Defaults: folder `Pictures/Yolla`, a generated token, no tunnel.

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.ps1 | iex
```

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh | bash
```

The script checks Docker, writes a config, pulls the image, starts Yolla, and prints the address on this computer, the address on your Wi‑Fi and the token.

Don't like piping a script into your shell? Fair. Download it, read it (it's about 200 lines), then run it:

```bash
curl -fsSLO https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh && less install.sh && bash install.sh
```

### With options

Same thing, choosing the three settings yourself. Here: a folder on `D:`, your own token, and a quick tunnel so it works from anywhere right away.

```powershell
# Windows
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.ps1))) -Dir "D:\Photos\Yolla" -Token "mysecret" -Tunnel quick
```
```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh | bash -s -- --dir ~/Pictures/Yolla --token mysecret --tunnel quick
```

Changed your mind? Run it again with other options, for example add `--tunnel quick` to an existing install. Everything you don't pass again is kept.

| Option (sh / ps1) | What it does |
|---|---|
| `--dir` / `-Dir` | Folder that receives the files. Default `~/Pictures/Yolla`. |
| `--token` / `-Token` | Access token. Omit it and one is generated. `--no-token` / `-NoToken` turns it off (LAN only, please). |
| `--port` / `-Port` | Port on this machine. Default `8080`. |
| `--tunnel` / `-Tunnel` | `quick`, `cloudflare` (+ `--cf-token`), `ngrok` (+ `--ngrok-token`, optionally `--ngrok-domain`) or `none`. |
| `--group-by-date` / `-GroupByDate` | Save into `YYYY/YYYY-MM/` by photo date. |
| `--max-mb` / `-MaxMb` | Reject single files bigger than this. Default 0 = no limit. |
| `--no-outbox` / `-NoOutbox` | Turn off the Receive tab, so nothing at all can be read from the phone. |
| `--update`, `--status`, `--uninstall` / `-Update`, `-Status`, `-Uninstall` | Maintenance. Uninstall never touches your files. |

The script writes a `.env` and a `docker-compose.yml` to `~/.yolla/` (Windows: `%LOCALAPPDATA%\Yolla\`). Edit them by hand if you like; `--update` applies changes.

### By hand

```bash
docker run -d --name yolla --restart unless-stopped -p 8080:8080 \
  -v "/path/to/folder:/data" -e UPLOAD_TOKEN=mysecret \
  ghcr.io/tekyaygilfethi/yolla:latest
```

Windows paths go with forward slashes: `-v "C:/Users/you/Pictures/Yolla:/data"`. The container runs as user 1000; on Linux, if your folder belongs to a different user, add `--user "$(id -u):$(id -g)"`. Compose users: `git clone`, `cp .env.example .env`, edit, `docker compose up -d`. No Docker? With the [.NET 10 SDK](https://dotnet.microsoft.com/download): `cd src/Yolla && UPLOAD_DIR=/path UPLOAD_TOKEN=mysecret dotnet run -c Release`.

## Use

1. On the computer: <http://localhost:8080>. From a phone on the same Wi‑Fi: `http://<computer-ip>:8080` (the installer prints it). No tunnel involved, so this is the fastest path.
2. The first visit asks for the token. It's remembered on that device. To enter a different one later, tap *change token* next to the folder stats.
3. **Photos & Videos** opens the phone's photo picker. Pick what you want; the upload starts right away. **Any file** opens the file browser instead, for documents, ZIPs and, on iPhone, original videos (see below).
4. **Subfolder** is optional; `Holiday2026` puts this batch in a subfolder of that name.
5. Keep the page open until it says **Done**. If it doesn't, pick the same files again and it resumes.
6. **Receive**: on the computer, put files into the `Outbox` folder inside your Yolla folder. On the phone open the Receive tab, tap what you want, then *Download* (one file, or a ZIP for several) or, on iPhone, *Save to Photos*.

## Reach it from anywhere

Yolla is a plain HTTP server on port 8080. Anything that can forward HTTP to it works. Pick one:

**Cloudflare Tunnel** is the one I'd recommend. Free, no bandwidth cap, HTTPS, no port forwarding, works behind CGNAT.

- Quick tunnel, no account: `--tunnel quick` in the installer, or `docker compose --profile quick up -d`, or with cloudflared installed on the machine, `cloudflared tunnel --url http://localhost:8080`. You get a random `https://….trycloudflare.com` address that changes on every restart. Good for "send me the photos now".
- Named tunnel, your own domain, permanent address: in the [Zero Trust dashboard](https://one.dash.cloudflare.com) go to **Networks → Tunnels → Create a tunnel → Cloudflared**, pick **Docker** and copy the token. Run the installer with `--tunnel cloudflare --cf-token <token>` (or put it in `.env` and use the `cloudflare` profile). Back in the dashboard add a **Public Hostname**: subdomain `yolla`, your domain, service **HTTP**, URL `yolla:8080`. Open `https://yolla.yourdomain.com` on the phone. If you want a proper login screen in front, add **Cloudflare Access** (Access → Applications → Self-hosted, one-time PIN by e-mail); the free plan covers up to 50 users.

**ngrok** is the quickest way to get a URL for a test. Sign up, run `ngrok config add-authtoken <token>`, then `ngrok http 8080`. Or `--tunnel ngrok --ngrok-token <token>` in the installer; the URL is at <http://localhost:4040>. Claim the free static domain in the ngrok dashboard and pass `--ngrok-domain name.ngrok-free.app` to keep the same URL. The first visit shows ngrok's interstitial page; tap **Visit Site** once. Yolla sends the header that skips it for API calls, so uploads aren't affected.

**Your own reverse proxy** (Caddy, nginx, Traefik, NPM) or **Tailscale**: see [docs/reverse-proxy.md](docs/reverse-proxy.md). Only two settings matter: raise the request body limit and turn off request buffering.

## Good to know

- **Videos picked from Photos on an iPhone lose quality.** Safari re-encodes them (HEVC to H.264 at a lower bitrate; 4K/60 gets visibly softer, and some people report the audio track going missing). No web page can turn this off. For untouched originals use **Any file → Files app** (save the video to Files first) or the short Shortcut in [docs/ios-originals.md](docs/ios-originals.md), which also gives you original HEIC photos. Photos picked from Photos arrive as full-resolution JPEG converted from HEIC, which is fine for almost everyone.
- **ngrok's free plan is about 1 GB of transfer a month.** That's one holiday album. Use Cloudflare or the LAN for big batches.
- **Cloudflare takes 100 MB per request** on free plans. That's why uploads are chunked; keep `CHUNK_MB` under 100.
- **Keep the screen on.** Over HTTPS Yolla asks iOS to keep the screen awake. On plain `http://` LAN addresses it can't, so turn off auto-lock yourself. Selecting hundreds of items also takes a moment before the upload starts; that's iOS preparing them.
- **Set a token** unless you never leave your own Wi‑Fi.
- **Windows firewall:** if the phone can't reach `http://<pc-ip>:8080`, allow TCP 8080 for Docker Desktop.
- **Linux permissions:** the container runs as uid 1000. The installer sets `PUID`/`PGID` to your user; with `docker run`, add `--user`.

## Configuration

Environment variables. The installer writes them to `.env`.

| Variable | Default | Meaning |
|---|---|---|
| `UPLOAD_DIR` | `/data` in Docker, `./uploads` with `dotnet run` | Where files are written. |
| `UPLOAD_TOKEN` | empty = no auth | Shared secret, sent as `X-Upload-Token` header or `?token=`. |
| `GROUP_BY_DATE` | `false` | `true` puts files under `2026/2026-09/` by photo date. |
| `CHUNK_MB` | `32` | Upload chunk size. |
| `MAX_UPLOAD_MB` | `0` (no limit) | Reject single files bigger than this. |
| `SHARE_DIR` | `<UPLOAD_DIR>/Outbox` | The one folder the phone may read (Receive tab). `off` disables it. |
| `ASPNETCORE_HTTP_PORTS` | `8080` | Port inside the container. |

Compose adds `YOLLA_DIR`, `YOLLA_PORT`, `YOLLA_BIND` (`127.0.0.1` behind a local proxy), `YOLLA_IMAGE`, `PUID`/`PGID` and `COMPOSE_PROFILES=quick|cloudflare|ngrok`; see [.env.example](.env.example).

## How it works

Before each file, the page asks `GET /api/exists`: is it already there (skip) or half there (resume from that byte)? Then it sends the file in chunks with `PUT /api/upload`; each chunk is a raw request body appended to a `.part` file. The last chunk renames the file into place and restores its timestamp. Nothing is held in memory, so memory use stays flat no matter how big the file is. The Receive tab reads only the Outbox folder: `GET /api/outbox` lists it, `/api/outbox/file` serves one file (with range requests, so videos scrub), `/api/outbox/zip` streams several as a ZIP. The full API, including a one-line `curl -T`, is in [docs/api.md](docs/api.md).

There's an end-to-end test in `tests/smoke.sh` that publishes the app, starts it and hits every endpoint (chunking, resume, dedupe, size cap, throttling). It runs in CI.

## Roadmap

- [ ] Thumbnails in the Receive tab
- [ ] QR code / invite link for giving family access
- [ ] Optional server-side HEIC → JPEG
- [ ] Multiple tokens, one subfolder per person
- [ ] Single-exe Windows tray app, no Docker

## Contributing, security, licence

Issues and small, dependency-free PRs are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md). Security notes and how to report a problem are in [SECURITY.md](SECURITY.md). [MIT](LICENSE).

<p align="center"><img src="src/Yolla/wwwroot/icon.svg" width="88" height="88" alt="Yolla"></p>
<h1 align="center">Yolla</h1>
<p align="center">Lightweight file transfers on your own computer or server.<br>Open source. Browser access. Storage you control.</p>

<p align="center">
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt=".NET 10" src="https://img.shields.io/badge/.NET-10-512BD4">
  <img alt="Docker amd64 | arm64" src="https://img.shields.io/badge/docker-amd64%20%7C%20arm64-2496ED">
  <a href="README.tr.md"><img alt="Türkçe" src="https://img.shields.io/badge/README-T%C3%BCrk%C3%A7e-red"></a>
</p>

<p align="center"><img src="docs/demo.gif" width="300" alt="Yolla on an iPhone: pick 13 photos, watch them land on the PC">&nbsp;&nbsp;<img src="docs/receive-dark.png" width="300" alt="Receive tab in dark mode"></p>

## What is Yolla?

Yolla is a lightweight, open-source file transfer tool you run on your own computer or server. Open its address in a browser to send photos, videos and other files directly to a folder you choose. To transfer files the other way, put them in the server's `Outbox` folder and download them from the **Receive** tab on another device.

Photos, videos and other files can be transferred from an iPhone, Android phone, tablet or computer through a simple web page. The sending device only needs a browser and access to the Yolla address. The server can run on Windows, macOS or Linux, including compatible NAS and Raspberry Pi setups.

Yolla is a small personal tool with a deliberately narrow scope. Its aim is not to compete with major storage platforms or replace their full feature sets. It offers a lightweight way to transfer files on infrastructure you control, with a small codebase you can inspect and adapt.

## Why Yolla?

- **Choose where your files live.** Uploads are saved in an ordinary folder on your computer or server. You choose the disk and folder, and can open the files with your usual tools.
- **Use a browser on the sending device.** No phone app or Yolla account is required. Set up the server once, then open its address and enter your access password.
- **Set the limits that suit you.** Configure the shared access password, maximum file size and upload subfolders. Choose which folder is available for downloads, or turn downloads off entirely.
- **Transfer in both directions.** Devices that can reach your Yolla address and authenticate can upload files and download the files you place in `Outbox`.
- **Reach your server while away.** Configure a tunnel or your own HTTPS reverse proxy to use Yolla outside your local network. Your server must stay running, have enough disk space and be reachable from the sending device.
- **Use storage you already have.** You can move a batch of travel photos to your own disk without buying an additional cloud storage subscription. Storage, connectivity and any hosting or tunnel costs depend on your setup.
- **Keep the setup small.** The application logic lives in one C# file and one HTML file, with no third-party NuGet or JavaScript packages and no separate database. The documented setup uses Docker, or you can run it with .NET 10. The web page includes no third-party scripts or analytics.
- **Inspect and adapt it.** Yolla is free software under the MIT licence. Read the code, modify it for your needs or contribute a change.

## When it fits

Yolla fits when you want to send files to your own machine and make selected files available through a browser. For example, you can send photos to your home server while travelling, collect files from several of your devices in one folder, or put a document in `Outbox` to download on your phone.

It handles transfers you start yourself. It does not provide automatic background photo backup, a synchronised photo library, storage redundancy or separate user accounts. If you need those features, a dedicated storage or backup service may fit better. Yolla does not automatically free space on your phone: before deleting local copies, check the transferred files and keep a separate backup of anything important.

## What it does

- Transfers the bytes provided by the browser without recompressing photos or videos. The device may convert media before upload; see the iPhone note below.
- Uploads three files at a time with retries, and shows progress, speed and time left.
- Streams every file to disk in 32 MB pieces. A dropped connection costs you at most one piece; re-select the same files and it resumes from the exact byte.
- Never overwrites existing files. The browser skips a file if its name and size match an existing upload; this is not a content comparison. Other name collisions get a suffix such as `IMG_0001 (1).JPG`.
- Preserves the last-modified timestamp supplied by the browser, where the filesystem supports it. Optional `YYYY/YYYY-MM/` subfolders use that timestamp; the app does not extract the capture date from EXIF.
- **Receive** tab: put files in the `Outbox` folder on the computer and they appear on the phone. Download one, several as a ZIP, or on iPhone tap *Save to Photos* and they go straight into the gallery.
- Uses a browser interface. Drag & drop and paste on desktop. A second button takes non-media files. Light and dark theme, English and Turkish. On iPhone, *Add to Home Screen* gives you an app icon.
- Optional access token, optional size cap, optional subfolder per batch.
- Runs behind Cloudflare Tunnel, ngrok, your own reverse proxy (even under a sub-path) or plain LAN. Chunks stay under Cloudflare's 100 MB request limit.

## Install

### Three things to decide first

The installer uses defaults for Yolla settings, which you can change by running it again. If Docker is missing, it may ask before installing it. It's still worth knowing what it sets up:

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

**Cloudflare Tunnel** provides HTTPS access without router port forwarding and can be used behind CGNAT.

- Quick tunnel, no account: `--tunnel quick` in the installer, or `docker compose --profile quick up -d`, or with cloudflared installed on the machine, `cloudflared tunnel --url http://localhost:8080`. A random `https://….trycloudflare.com` address is assigned and changes on every restart. Suitable for temporary transfers.
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

Before each file, the page asks `GET /api/exists`: is it already there (skip) or half there (resume from that byte)? Then it sends the file in chunks with `PUT /api/upload`; each chunk is a raw request body appended to a `.part` file. The last chunk renames the file into place and restores its timestamp. Uploads use a fixed-size buffer rather than loading the whole file into memory. The Receive tab reads only the Outbox folder: `GET /api/outbox` lists it, `/api/outbox/file` serves one file (with range requests, so videos scrub), `/api/outbox/zip` streams several as a ZIP. The full API, including a one-line `curl -T`, is in [docs/api.md](docs/api.md).

There's an end-to-end test in `tests/smoke.sh` that publishes the app, starts it and hits every endpoint (chunking, resume, dedupe, size cap, throttling). It runs in CI.

## Roadmap

- [ ] Thumbnails in the Receive tab
- [ ] QR code / invite link for giving family access
- [ ] Optional server-side HEIC → JPEG
- [ ] Multiple tokens, one subfolder per person
- [ ] Single-exe Windows tray app, no Docker

## Contributing, security, licence

Issues and small, dependency-free PRs are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md). Security notes and how to report a problem are in [SECURITY.md](SECURITY.md). [MIT](LICENSE).

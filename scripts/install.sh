#!/usr/bin/env bash
# ------------------------------------------------------------------------------------------------
#  Yolla installer — Linux & macOS            https://github.com/TekyaygilFethi/yolla
#
#  One line:
#    curl -fsSL https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh | bash
#  With options:
#    curl -fsSL .../install.sh | bash -s -- --dir ~/Pictures/Yolla --token mysecret --tunnel quick
#
#  What it does: checks Docker, writes ~/.yolla/{.env,docker-compose.yml}, pulls the image, starts
#  Yolla (and optionally a tunnel), prints the URLs and the access token. Re-run any time; your
#  token and settings are kept unless you pass new ones.
# ------------------------------------------------------------------------------------------------
set -euo pipefail

REPO="TekyaygilFethi/yolla"
IMAGE="${YOLLA_IMAGE:-ghcr.io/$REPO:latest}"

# Run under sudo? Then the real user is $SUDO_USER: use their home and uid so the files end up theirs.
RUN_USER="${SUDO_USER:-$(id -un)}"
RUN_HOME="$(getent passwd "$RUN_USER" 2>/dev/null | cut -d: -f6)"; RUN_HOME="${RUN_HOME:-$HOME}"
RUN_UID="$(id -u "$RUN_USER")"; RUN_GID="$(id -g "$RUN_USER")"
INSTALL_DIR="${YOLLA_HOME:-$RUN_HOME/.yolla}"
DATA_DIR="$RUN_HOME/Pictures/Yolla"
TOKEN=""; NO_TOKEN=0; PORT=8080; BIND="0.0.0.0"; TUNNEL=""; CF_TOKEN=""; NGROK_TOKEN=""; NGROK_DOMAIN=""
GROUP_BY_DATE=""; CHUNK_MB=""; MAX_MB=""; OUTBOX=""; ACTION="install"; YES=0

usage() {
  cat <<EOF
Yolla installer (Linux / macOS)

  --dir <folder>        Folder that receives uploads          (default: $DATA_DIR)
  --token <secret>      Access token / password               (default: generated on first install)
  --no-token            Disable the token (anyone with the URL can upload — LAN only!)
  --port <n>            Port on this machine                  (default: 8080)
  --bind <ip>           Bind address, e.g. 127.0.0.1 behind a local reverse proxy (default: 0.0.0.0)
  --tunnel <kind>       none | quick | cloudflare | ngrok     (default: none)
                          quick      = Cloudflare quick tunnel, random URL, no account
                          cloudflare = Cloudflare named tunnel, needs --cf-token
                          ngrok      = ngrok, needs --ngrok-token (optional --ngrok-domain)
  --cf-token <t>        Cloudflare tunnel token (Zero Trust -> Networks -> Tunnels -> Docker)
  --ngrok-token <t>     ngrok authtoken
  --ngrok-domain <d>    ngrok static domain, e.g. name.ngrok-free.app
  --group-by-date       Save into <folder>/YYYY/YYYY-MM/ by photo date
  --chunk-mb <n>        Upload chunk size in MB (default 32; keep < 100 with Cloudflare)
  --max-mb <n>          Reject single files larger than n MB (default 0 = unlimited)
  --no-outbox           Disable the Receive tab (no folder is ever readable from the phone)
  --image <ref>         Docker image (default: $IMAGE)
  --yes                 Don't ask before installing Docker (Linux)
  --update              Pull the latest image and restart
  --status              Show container status and URLs
  --uninstall           Stop and remove Yolla (your uploaded files are NOT touched)
  -h, --help            This help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DATA_DIR="$2"; shift 2 ;;
    --token|--password) TOKEN="$2"; shift 2 ;;
    --no-token) NO_TOKEN=1; shift ;;
    --port) PORT="$2"; shift 2 ;;
    --bind) BIND="$2"; shift 2 ;;
    --tunnel) TUNNEL="$2"; shift 2 ;;
    --cf-token) CF_TOKEN="$2"; shift 2 ;;
    --ngrok-token) NGROK_TOKEN="$2"; shift 2 ;;
    --ngrok-domain) NGROK_DOMAIN="$2"; shift 2 ;;
    --group-by-date) GROUP_BY_DATE="true"; shift ;;
    --chunk-mb) CHUNK_MB="$2"; shift 2 ;;
    --max-mb) MAX_MB="$2"; shift 2 ;;
    --no-outbox) OUTBOX="off"; shift ;;
    --image) IMAGE="$2"; shift 2 ;;
    --yes|-y) YES=1; shift ;;
    --update) ACTION="update"; shift ;;
    --status) ACTION="status"; shift ;;
    --uninstall) ACTION="uninstall"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m ✗\033[0m %s\n' "$*" >&2; exit 1; }

OS="$(uname -s)"
compose() { docker compose --project-directory "$INSTALL_DIR" "$@"; }

# ---- read existing settings so re-runs don't rotate the token ---------------------------------
ENV_FILE="$INSTALL_DIR/.env"
env_get() { [[ -f "$ENV_FILE" ]] && sed -n "s/^$1=//p" "$ENV_FILE" | head -1 || true; }
if [[ -f "$ENV_FILE" ]]; then
  [[ -z "$TOKEN" && $NO_TOKEN -eq 0 ]] && TOKEN="$(env_get UPLOAD_TOKEN)"
  [[ -z "$TUNNEL" ]] && TUNNEL="$(env_get COMPOSE_PROFILES)"
  [[ -z "$CF_TOKEN" ]] && CF_TOKEN="$(env_get CLOUDFLARE_TUNNEL_TOKEN)"
  [[ -z "$NGROK_TOKEN" ]] && NGROK_TOKEN="$(env_get NGROK_AUTHTOKEN)"
  [[ -z "$NGROK_DOMAIN" ]] && NGROK_DOMAIN="$(env_get NGROK_DOMAIN)"
  [[ -z "$GROUP_BY_DATE" ]] && GROUP_BY_DATE="$(env_get GROUP_BY_DATE)"
  [[ -z "$CHUNK_MB" ]] && CHUNK_MB="$(env_get CHUNK_MB)"
  [[ -z "$MAX_MB" ]] && MAX_MB="$(env_get MAX_UPLOAD_MB)"
  [[ -z "$OUTBOX" ]] && OUTBOX="$(env_get SHARE_DIR)"
  if [[ "$DATA_DIR" == "$RUN_HOME/Pictures/Yolla" ]]; then d="$(env_get YOLLA_DIR)"; [[ -n "$d" ]] && DATA_DIR="$d"; fi
  if [[ "$PORT" == "8080" ]]; then p="$(env_get YOLLA_PORT)"; [[ -n "$p" ]] && PORT="$p"; fi
fi
TUNNEL="${TUNNEL:-none}"; GROUP_BY_DATE="${GROUP_BY_DATE:-false}"; CHUNK_MB="${CHUNK_MB:-32}"; MAX_MB="${MAX_MB:-0}"; OUTBOX="${OUTBOX:-/data/Outbox}"
[[ "$TUNNEL" =~ ^(none|quick|cloudflare|ngrok)$ ]] || die "--tunnel must be none, quick, cloudflare or ngrok"
[[ "$TUNNEL" == "cloudflare" && -z "$CF_TOKEN" ]] && die "--tunnel cloudflare needs --cf-token"
[[ "$TUNNEL" == "ngrok" && -z "$NGROK_TOKEN" ]] && die "--tunnel ngrok needs --ngrok-token"

lan_ip() {
  if [[ "$OS" == "Darwin" ]]; then ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true
  else hostname -I 2>/dev/null | awk '{print $1}' || true; fi
}

print_urls() {
  local ip; ip="$(lan_ip)"
  echo
  ok "Yolla is running."
  echo "   On this machine : http://localhost:$PORT"
  [[ -n "$ip" ]] && echo "   Same Wi-Fi      : http://$ip:$PORT"
  case "$TUNNEL" in
    quick)
      say "Waiting for the Cloudflare quick tunnel URL…"
      local url=""; for _ in $(seq 1 30); do
        url="$(compose logs cloudflared-quick 2>/dev/null | grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1 || true)"
        [[ -n "$url" ]] && break; sleep 1; done
      if [[ -n "$url" ]]; then echo "   From anywhere   : $url   (changes every restart)"; else warn "No URL yet — run:  docker compose --project-directory $INSTALL_DIR logs cloudflared-quick"; fi ;;
    ngrok)
      local url=""; for _ in $(seq 1 20); do
        url="$(curl -fs http://127.0.0.1:4040/api/tunnels 2>/dev/null | grep -Eo 'https://[^"]+' | head -1 || true)"
        [[ -n "$url" ]] && break; sleep 1; done
      if [[ -n "$url" ]]; then echo "   From anywhere   : $url"; else warn "ngrok URL not ready — open http://localhost:4040"; fi ;;
    cloudflare)
      echo "   From anywhere   : the public hostname you set in Zero Trust (Service: HTTP, URL: yolla:8080)" ;;
  esac
  if [[ -n "$TOKEN" ]]; then echo; echo "   Access token    : $TOKEN"; echo "   (the phone asks for it once; it's in $ENV_FILE)"; else warn "No token set — anyone who can reach the URL can upload."; fi
  echo "   Files land in   : $DATA_DIR"
  [[ "$OUTBOX" != "off" ]] && echo "   To your phone   : put files in $DATA_DIR/Outbox and open the Receive tab"
  echo
}

# ---- actions that don't need a fresh install --------------------------------------------------
case "$ACTION" in
  status)   compose ps; print_urls; exit 0 ;;
  update)   say "Updating…"; compose pull; compose up -d --remove-orphans; ok "Updated."; print_urls; exit 0 ;;
  uninstall)
    say "Stopping and removing Yolla containers…"; compose down --remove-orphans 2>/dev/null || true
    case "$INSTALL_DIR" in /|"$HOME"|"$RUN_HOME"|"") die "Refusing to remove $INSTALL_DIR" ;; esac
    [[ -f "$INSTALL_DIR/docker-compose.yml" ]] && rm -rf "$INSTALL_DIR"
    ok "Removed $INSTALL_DIR. Your files in $DATA_DIR were not touched."; exit 0 ;;
esac

# ---- docker ------------------------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  if [[ "$OS" == "Linux" ]]; then
    warn "Docker is not installed."
    if [[ $YES -eq 1 ]] || { read -r -p "Install Docker now with get.docker.com? [y/N] " a </dev/tty && [[ "$a" =~ ^[Yy]$ ]]; }; then
      curl -fsSL https://get.docker.com | sh
      if command -v usermod >/dev/null 2>&1 && [[ -n "${SUDO_USER:-}" ]]; then sudo usermod -aG docker "$SUDO_USER" || true; fi
      warn "If 'docker' now says permission denied, log out and back in (or run this script with sudo)."
    else die "Install Docker (https://docs.docker.com/engine/install/) and re-run."; fi
  else
    die "Docker is not installed. Install Docker Desktop (https://docker.com/products/docker-desktop) or OrbStack, start it, and re-run."
  fi
fi
docker info >/dev/null 2>&1 || die "Docker is installed but not running (or you lack permission). Start Docker and re-run."
docker compose version >/dev/null 2>&1 || die "The 'docker compose' plugin is missing — install Docker Compose v2."

# ---- token & folders ---------------------------------------------------------------------------
if [[ -z "$TOKEN" && $NO_TOKEN -eq 0 ]]; then
  TOKEN="$( (openssl rand -hex 12 2>/dev/null || head -c 48 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 24) )"
  say "No --token given — generated one for you."
fi
[[ $NO_TOKEN -eq 1 ]] && TOKEN=""
mkdir -p "$DATA_DIR" "$INSTALL_DIR"
DATA_DIR="$(cd "$DATA_DIR" && pwd)"
[[ -n "${SUDO_USER:-}" ]] && chown "$RUN_UID:$RUN_GID" "$DATA_DIR" "$INSTALL_DIR" 2>/dev/null || true

# ---- write config ------------------------------------------------------------------------------
cat > "$ENV_FILE" <<EOF
# Generated by install.sh on $(date '+%Y-%m-%d %H:%M'). Edit and re-run 'install.sh --update' to apply.
YOLLA_IMAGE=$IMAGE
YOLLA_DIR=$DATA_DIR
YOLLA_PORT=$PORT
YOLLA_BIND=$BIND
UPLOAD_TOKEN=$TOKEN
GROUP_BY_DATE=$GROUP_BY_DATE
CHUNK_MB=$CHUNK_MB
MAX_UPLOAD_MB=$MAX_MB
SHARE_DIR=$OUTBOX
PUID=$RUN_UID
PGID=$RUN_GID
COMPOSE_PROFILES=$([[ "$TUNNEL" == "none" ]] && echo "" || echo "$TUNNEL")
CLOUDFLARE_TUNNEL_TOKEN=$CF_TOKEN
NGROK_AUTHTOKEN=$NGROK_TOKEN
NGROK_DOMAIN=$NGROK_DOMAIN
EOF
chmod 600 "$ENV_FILE"

cat > "$INSTALL_DIR/docker-compose.yml" <<'EOF'
# Generated by install.sh — settings live in .env next to this file.
services:
  yolla:
    image: ${YOLLA_IMAGE}
    container_name: yolla
    user: "${PUID:-1000}:${PGID:-1000}"
    ports:
      - "${YOLLA_BIND:-0.0.0.0}:${YOLLA_PORT:-8080}:8080"
    volumes:
      - "${YOLLA_DIR}:/data"
    environment:
      - UPLOAD_TOKEN=${UPLOAD_TOKEN:-}
      - GROUP_BY_DATE=${GROUP_BY_DATE:-false}
      - CHUNK_MB=${CHUNK_MB:-32}
      - MAX_UPLOAD_MB=${MAX_UPLOAD_MB:-0}
      - SHARE_DIR=${SHARE_DIR:-/data/Outbox}
    restart: unless-stopped
  cloudflared:
    image: cloudflare/cloudflared:latest
    profiles: ["cloudflare"]
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    depends_on: [yolla]
    restart: unless-stopped
  cloudflared-quick:
    image: cloudflare/cloudflared:latest
    profiles: ["quick"]
    command: tunnel --no-autoupdate --url http://yolla:8080
    depends_on: [yolla]
    restart: unless-stopped
  ngrok:
    image: ngrok/ngrok:latest
    profiles: ["ngrok"]
    command: http ${NGROK_DOMAIN:+--url=${NGROK_DOMAIN}} yolla:8080
    environment:
      - NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN}
    ports:
      - "127.0.0.1:4040:4040"
    depends_on: [yolla]
    restart: unless-stopped
EOF
ok "Config written to $INSTALL_DIR"

# ---- start -------------------------------------------------------------------------------------
say "Pulling $IMAGE …"
compose pull
say "Starting Yolla$([[ "$TUNNEL" != "none" ]] && echo " (tunnel: $TUNNEL)")…"
compose up -d --remove-orphans
for _ in $(seq 1 20); do curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1 && break; sleep 1; done
print_urls
echo "   Manage: re-run this script with --status | --update | --uninstall"

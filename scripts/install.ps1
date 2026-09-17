<#
.SYNOPSIS
  Yolla installer for Windows.            https://github.com/TekyaygilFethi/yolla

.DESCRIPTION
  Checks Docker Desktop, writes %LOCALAPPDATA%\Yolla\{.env, docker-compose.yml}, pulls the image,
  starts Yolla (and optionally a tunnel), prints the URLs and the access token.
  Re-run any time; your token and settings are kept unless you pass new ones.

.EXAMPLE
  # one line (PowerShell):
  irm https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.ps1 | iex

.EXAMPLE
  # with options:
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.ps1))) -Dir "D:\Photos\Yolla" -Token "mysecret" -Tunnel quick

.EXAMPLE
  .\install.ps1 -Dir "D:\Photos\Yolla" -Token "mysecret" -Tunnel ngrok -NgrokToken "2abc..." -NgrokDomain "me.ngrok-free.app"
#>
[CmdletBinding()]
param(
  [string]$Dir,                                        # folder that receives uploads (default: %USERPROFILE%\Pictures\Yolla)
  [string]$Token,                                      # access token (default: generated on first install)
  [switch]$NoToken,                                    # disable the token (LAN only!)
  [int]$Port = 0,                                      # port on this machine (default 8080)
  [string]$Bind = "",                                  # 127.0.0.1 behind a local reverse proxy (default 0.0.0.0)
  [string]$Tunnel = '',                                # none | quick | cloudflare | ngrok
  [string]$CfToken,                                    # Cloudflare named tunnel token
  [string]$NgrokToken,                                 # ngrok authtoken
  [string]$NgrokDomain,                                # ngrok static domain (optional)
  [switch]$GroupByDate,                                # <folder>\YYYY\YYYY-MM\ by photo date
  [int]$ChunkMb = 0,                                   # default 32; keep < 100 with Cloudflare
  [int]$MaxMb = -1,                                    # reject single files larger than this (MB); 0 = unlimited
  [switch]$NoOutbox,                                   # disable the Receive tab
  [string]$Image = "",                                 # default ghcr.io/tekyaygilfethi/yolla:latest
  [switch]$Yes,                                        # don't ask before installing Docker Desktop
  [switch]$Update,
  [switch]$Status,
  [switch]$Uninstall,
  [switch]$NoBrowser                                   # don't open the browser at the end
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false   # PS 7.3+: don't turn non-zero exit codes into exceptions
$Repo       = "TekyaygilFethi/yolla"
$InstallDir = Join-Path $env:LOCALAPPDATA "Yolla"
$EnvFile    = Join-Path $InstallDir ".env"

function Say($m)  { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host " OK $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  ! $m" -ForegroundColor Yellow }
function Die($m)  { Write-Host "  X $m" -ForegroundColor Red; throw "Yolla installer stopped: $m" }
function Compose  { & docker compose --project-directory $InstallDir @args; if ($LASTEXITCODE -ne 0) { Die "docker compose $($args -join ' ') failed" } }
function EnvGet($k) {
  if (-not (Test-Path $EnvFile)) { return "" }
  $line = Get-Content $EnvFile | Where-Object { $_ -like "$k=*" } | Select-Object -First 1
  if ($line) { return $line.Substring($k.Length + 1) } else { return "" }
}

# ---- merge with existing settings so re-runs keep the token -----------------------------------
if (-not $Dir)                 { $Dir = EnvGet "YOLLA_DIR" }
if (-not $Dir)                 { $Dir = Join-Path $env:USERPROFILE "Pictures\Yolla" }
if (-not $Token -and -not $NoToken) { $Token = EnvGet "UPLOAD_TOKEN" }
if ($Port -eq 0)               { $p = EnvGet "YOLLA_PORT"; $Port = if ($p) { [int]$p } else { 8080 } }
if (-not $Bind)                { $Bind = EnvGet "YOLLA_BIND"; if (-not $Bind) { $Bind = "0.0.0.0" } }
if (-not $Tunnel)              { $Tunnel = EnvGet "COMPOSE_PROFILES"; if (-not $Tunnel) { $Tunnel = "none" } }
if (-not $CfToken)             { $CfToken = EnvGet "CLOUDFLARE_TUNNEL_TOKEN" }
if (-not $NgrokToken)          { $NgrokToken = EnvGet "NGROK_AUTHTOKEN" }
if (-not $NgrokDomain)         { $NgrokDomain = EnvGet "NGROK_DOMAIN" }
$Group = if ($GroupByDate) { "true" } else { $g = EnvGet "GROUP_BY_DATE"; if ($g) { $g } else { "false" } }
if ($ChunkMb -eq 0)            { $c = EnvGet "CHUNK_MB"; $ChunkMb = if ($c) { [int]$c } else { 32 } }
if ($MaxMb -lt 0)              { $m = EnvGet "MAX_UPLOAD_MB"; $MaxMb = if ($m) { [int]$m } else { 0 } }
$Outbox = if ($NoOutbox) { "off" } else { $o = EnvGet "SHARE_DIR"; if ($o) { $o } else { "/data/Outbox" } }
if (-not $Image)               { $Image = EnvGet "YOLLA_IMAGE"; if (-not $Image) { $Image = "ghcr.io/${Repo}:latest" } }
if ($Tunnel -notmatch '^(none|quick|cloudflare|ngrok)$') { Die "-Tunnel must be none, quick, cloudflare or ngrok" }
if ($Tunnel -eq 'cloudflare' -and -not $CfToken)  { Die "-Tunnel cloudflare needs -CfToken" }
if ($Tunnel -eq 'ngrok' -and -not $NgrokToken)    { Die "-Tunnel ngrok needs -NgrokToken" }

function LanIp {
  try {
    (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
      Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' -and $_.InterfaceAlias -notmatch 'vEthernet|WSL|Docker|Loopback' } |
      Sort-Object InterfaceMetric | Select-Object -First 1).IPAddress
  } catch { "" }
}

function PrintUrls {
  $ip = LanIp
  Write-Host ""
  Ok "Yolla is running."
  Write-Host "   On this machine : http://localhost:$Port"
  if ($ip) { Write-Host "   Same Wi-Fi      : http://${ip}:$Port" }
  switch ($Tunnel) {
    'quick' {
      Say "Waiting for the Cloudflare quick tunnel URL..."
      $url = ""
      for ($i = 0; $i -lt 30 -and -not $url; $i++) {
        $log = (& cmd /c "docker compose --project-directory ""$InstallDir"" logs cloudflared-quick 2>&1") -join "`n"
        $m = [regex]::Matches($log, 'https://[a-z0-9-]+\.trycloudflare\.com'); if ($m.Count) { $url = $m[$m.Count - 1].Value }
        if (-not $url) { Start-Sleep 1 }
      }
      if ($url) { Write-Host "   From anywhere   : $url   (changes every restart)" } else { Warn "No URL yet - run: docker compose --project-directory `"$InstallDir`" logs cloudflared-quick" }
    }
    'ngrok' {
      $url = ""
      for ($i = 0; $i -lt 20 -and -not $url; $i++) {
        try { $url = (Invoke-RestMethod http://127.0.0.1:4040/api/tunnels -ErrorAction Stop).tunnels[0].public_url } catch { Start-Sleep 1 }
      }
      if ($url) { Write-Host "   From anywhere   : $url" } else { Warn "ngrok URL not ready - open http://localhost:4040" }
    }
    'cloudflare' { Write-Host "   From anywhere   : the public hostname you set in Zero Trust (Service: HTTP, URL: yolla:8080)" }
  }
  if ($Token) { Write-Host ""; Write-Host "   Access token    : $Token"; Write-Host "   (the phone asks for it once; it's in $EnvFile)" }
  else { Warn "No token set - anyone who can reach the URL can upload." }
  Write-Host "   Files land in   : $Dir"
  if ($Outbox -ne "off") { Write-Host "   To your phone   : put files in $Dir\Outbox and open the Receive tab" }
  Write-Host ""
}

# ---- actions that don't need a fresh install --------------------------------------------------
if ($Status)    { Compose ps; PrintUrls; return }
if ($Update)    { Say "Updating..."; Compose pull; Compose up -d --remove-orphans; Ok "Updated."; PrintUrls; return }
if ($Uninstall) {
  Say "Stopping and removing Yolla containers..."
  & cmd /c "docker compose --project-directory ""$InstallDir"" down --remove-orphans >nul 2>&1"
  if ((Test-Path (Join-Path $InstallDir "docker-compose.yml")) -and $InstallDir.Length -gt 10) { Remove-Item -Recurse -Force $InstallDir }
  Ok "Removed $InstallDir. Your files in $Dir were not touched."; return
}

# ---- docker ------------------------------------------------------------------------------------
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Warn "Docker Desktop is not installed."
  $go = [bool]$Yes
  if (-not $go) { $a = Read-Host "Install it now with winget? [y/N]"; $go = ($a -match '^[Yy]$') }
  if ($go -and (Get-Command winget -ErrorAction SilentlyContinue)) {
    & winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
    Die "Docker Desktop installed. Start it from the Start menu (finish its setup, it may ask to reboot), then re-run this script."
  }
  Die "Install Docker Desktop from https://docker.com/products/docker-desktop, start it, and re-run."
}
& cmd /c "docker info >nul 2>&1"
if ($LASTEXITCODE -ne 0) { Die "Docker is installed but not running. Start Docker Desktop (wait for the whale icon to settle) and re-run." }

# ---- token & folders ---------------------------------------------------------------------------
if (-not $Token -and -not $NoToken) {
  $chars = [char[]]'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  $Token = -join ((1..24) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
  Say "No -Token given - generated one for you."
}
if ($NoToken) { $Token = "" }
New-Item -ItemType Directory -Force -Path $Dir, $InstallDir | Out-Null
$Dir = (Resolve-Path $Dir).Path
$DirCompose = $Dir -replace '\\', '/'         # Docker Desktop wants C:/Users/... in compose

# ---- write config (UTF-8 without BOM - a BOM breaks .env parsing) -----------------------------
$profiles = if ($Tunnel -eq 'none') { "" } else { $Tunnel }
$envText = @"
# Generated by install.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Edit and re-run 'install.ps1 -Update' to apply.
YOLLA_IMAGE=$Image
YOLLA_DIR=$DirCompose
YOLLA_PORT=$Port
YOLLA_BIND=$Bind
UPLOAD_TOKEN=$Token
GROUP_BY_DATE=$Group
CHUNK_MB=$ChunkMb
MAX_UPLOAD_MB=$MaxMb
SHARE_DIR=$Outbox
PUID=1000
PGID=1000
COMPOSE_PROFILES=$profiles
CLOUDFLARE_TUNNEL_TOKEN=$CfToken
NGROK_AUTHTOKEN=$NgrokToken
NGROK_DOMAIN=$NgrokDomain
"@
$composeText = @'
# Generated by install.ps1 - settings live in .env next to this file.
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
'@
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($EnvFile, $envText.Replace("`r`n", "`n"), $utf8)
[IO.File]::WriteAllText((Join-Path $InstallDir "docker-compose.yml"), $composeText.Replace("`r`n", "`n"), $utf8)
Ok "Config written to $InstallDir"

# ---- start -------------------------------------------------------------------------------------
Say "Pulling $Image ..."
Compose pull
Say "Starting Yolla$(if ($Tunnel -ne 'none') { " (tunnel: $Tunnel)" })..."
Compose up -d --remove-orphans
for ($i = 0; $i -lt 20; $i++) { try { Invoke-WebRequest "http://127.0.0.1:$Port/healthz" -UseBasicParsing -TimeoutSec 2 | Out-Null; break } catch { Start-Sleep 1 } }
PrintUrls
Write-Host "   Manage: install.ps1 -Status | -Update | -Uninstall"
Write-Host "   Firewall: if phones on your Wi-Fi can't reach http://<pc-ip>:$Port, allow TCP $Port in Windows Defender Firewall."
if (-not $NoBrowser) { Start-Process "http://localhost:$Port" }

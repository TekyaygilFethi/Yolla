#!/usr/bin/env bash
# End-to-end smoke test: publishes the app, starts it with a token, and exercises every endpoint
# with curl — chunked upload, resume after an interrupted chunk, offset conflict, duplicate skip,
# name collision, sub-folder sanitising, size cap and auth throttling. Exits non-zero on any failure.
#
#   bash tests/smoke.sh            (needs the .NET 10 SDK and curl)
set -euo pipefail
cd "$(dirname "$0")/.."

PORT=${PORT:-18080}; B="http://127.0.0.1:$PORT"; H="X-Upload-Token: t3st"
TMP="$(mktemp -d)"; trap 'kill $PID 2>/dev/null || true; rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
check() { if [[ "$2" == *"$3"* ]]; then PASS=$((PASS+1)); echo " ✓ $1"; else FAIL=$((FAIL+1)); echo " ✗ $1"; echo "    got: $2"; echo "    want: $3"; fi; }

echo "== publish"
dotnet publish src/Yolla -c Release -o "$TMP/app" --nologo -v q >/dev/null
echo "== start"
mkdir -p "$TMP/data"
UPLOAD_DIR="$TMP/data" UPLOAD_TOKEN=t3st GROUP_BY_DATE=true CHUNK_MB=1 MAX_UPLOAD_MB=5 ASPNETCORE_URLS="$B" \
  dotnet "$TMP/app/Yolla.dll" >"$TMP/log" 2>&1 & PID=$!
for _ in $(seq 1 30); do curl -fs "$B/healthz" >/dev/null 2>&1 && break; sleep 0.5; done
curl -fs "$B/healthz" >/dev/null || { echo "server did not start"; cat "$TMP/log"; exit 1; }

head -c 3500000 /dev/urandom >"$TMP/big.mp4"; split -b 1000000 -d "$TMP/big.mp4" "$TMP/chunk_"
head -c 6000000 /dev/urandom >"$TMP/huge.bin"
mkdir -p "$TMP/data/Outbox/Trip"; head -c 300000 /dev/urandom >"$TMP/data/Outbox/photo.jpg"; echo hi >"$TMP/data/Outbox/Trip/notes.txt"; echo x >"$TMP/data/Outbox/.hidden"

echo "== checks"
check "page served"            "$(curl -s -o /dev/null -w '%{http_code}' "$B/")" "200"
check "manifest served"        "$(curl -s -o /dev/null -w '%{http_code}' "$B/manifest.webmanifest")" "200"
check "config is public"       "$(curl -s "$B/api/config")" '"tokenRequired":true'
check "stats needs token"      "$(curl -s -o /dev/null -w '%{http_code}' "$B/api/stats")" "401"
check "wrong token rejected"   "$(curl -s -o /dev/null -w '%{http_code}' -H 'X-Upload-Token: nope' "$B/api/stats")" "401"
check "query token accepted"   "$(curl -s "$B/api/stats?token=t3st")" '"count":0'

Q="name=big.mp4&size=3500000&id=abc123&mtime=1700000000000"
check "chunk 1"                "$(curl -s -H "$H" -X PUT --data-binary @"$TMP/chunk_00" "$B/api/upload?$Q&offset=0")" '"received":1000000'
check "chunk 2"                "$(curl -s -H "$H" -X PUT --data-binary @"$TMP/chunk_01" "$B/api/upload?$Q&offset=1000000")" '"received":2000000'
check "replayed chunk -> 409"  "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -X PUT --data-binary @"$TMP/chunk_01" "$B/api/upload?$Q&offset=1000000")" "409"
check "partial reported"       "$(curl -s -H "$H" "$B/api/exists?$Q")" '"partial":2000000'
check "chunk 3"                "$(curl -s -H "$H" -X PUT --data-binary @"$TMP/chunk_02" "$B/api/upload?$Q&offset=2000000")" '"received":3000000'
check "last chunk finalises"   "$(curl -s -H "$H" -X PUT --data-binary @"$TMP/chunk_03" "$B/api/upload?$Q&offset=3000000")" '"saved":"2023/2023-11/big.mp4"'
check "bytes identical"        "$(cmp "$TMP/big.mp4" "$TMP/data/2023/2023-11/big.mp4" && echo same)" "same"
check "timestamp restored"     "$(date -u -r "$TMP/data/2023/2023-11/big.mp4" +%Y-%m-%d)" "2023-11-14"
check "duplicate detected"     "$(curl -s -H "$H" "$B/api/exists?$Q")" '"exists":true'
check "collision gets (1)"     "$(curl -s -H "$H" -T "$TMP/chunk_00" "$B/api/upload?name=big.mp4&mtime=1700000000000")" '"saved":"2023/2023-11/big (1).mp4"'
check "empty file"             "$(curl -s -H "$H" -X PUT -H 'Content-Length: 0' "$B/api/upload?name=empty.txt&size=0&offset=0&id=e1")" '"done":true'
check "oversized declared"     "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -X PUT --data-binary @"$TMP/chunk_00" "$B/api/upload?name=x.bin&size=10&offset=0&id=o1")" "400"
check "size cap (declared)"    "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -X PUT -H 'Content-Length: 0' "$B/api/upload?name=h.bin&size=6000000&offset=0&id=h1")" "413"
check "size cap (streamed)"    "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -T "$TMP/huge.bin" "$B/api/upload?name=h2.bin")" "413"
check "traversal blocked"      "$(curl -s -H "$H" -T "$TMP/chunk_00" "$B/api/upload?name=..%2F..%2Fevil%3A%3F.bin&album=..%2F..%2F..%2Ftmp")" '"saved":"tmp/'
check "no stray files outside" "$(find "$TMP" -maxdepth 1 -name '*.bin' | wc -l | tr -d ' ')" "1"
check "recent lists uploads"   "$(curl -s -H "$H" "$B/api/recent?n=3")" '"name":"'
check "no .part left behind"   "$(find "$TMP/data" -name '*.part' | wc -l | tr -d ' ')" "0"
check "security headers"       "$(curl -s -I "$B/" | tr -d '\r' | grep -ci 'x-frame-options: DENY')" "1"

echo "== outbox (receive)"
check "stats exclude outbox"    "$(curl -s -H "$H" "$B/api/stats")" '"count":4'
check "outbox listed"           "$(curl -s -H "$H" "$B/api/outbox")" '"name":"photo.jpg"'
check "outbox folder first"     "$(curl -s -H "$H" "$B/api/outbox")" '"name":"Trip","dir":true'
check "outbox subfolder"        "$(curl -s -H "$H" "$B/api/outbox?path=Trip")" '"name":"notes.txt"'
check "hidden file skipped"     "$(curl -s -H "$H" "$B/api/outbox" | grep -c hidden)" "0"
check "outbox traversal"        "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" "$B/api/outbox?path=../2023")" "404"
check "uploads not readable"    "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" "$B/api/outbox/file?path=../2023/2023-11/big.mp4")" "404"
check "file served inline"      "$(curl -s -D - -o /dev/null -H "$H" "$B/api/outbox/file?path=photo.jpg" | tr -d '\r' | grep -i '^content-type')" "image/jpeg"
check "file download name"      "$(curl -s -D - -o /dev/null -H "$H" "$B/api/outbox/file?path=photo.jpg&dl=true" | tr -d '\r' | grep -i '^content-disposition')" "attachment"
check "range request"           "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H 'Range: bytes=0-99' "$B/api/outbox/file?path=photo.jpg")" "206"
check "cookie auth works"       "$(curl -s -o /dev/null -w '%{http_code}' --cookie 'yolla_token=t3st' "$B/api/outbox/file?path=photo.jpg")" "200"
curl -s -H "$H" "$B/api/outbox/zip?p=photo.jpg&p=Trip" -o "$TMP/out.zip"
check "zip streams"             "$(unzip -l "$TMP/out.zip" 2>/dev/null | grep -c -E 'photo.jpg|Trip/notes.txt')" "2"
check "zip content identical"   "$(cmp <(unzip -p "$TMP/out.zip" photo.jpg) "$TMP/data/Outbox/photo.jpg" && echo same)" "same"
check "outbox needs token"      "$(curl -s -o /dev/null -w '%{http_code}' "$B/api/outbox")" "401"

echo "== auth throttle (21 bad attempts)"
pids=(); for _ in $(seq 1 21); do curl -s -o /dev/null -H 'X-Upload-Token: bad' "$B/api/stats" & pids+=($!); done; wait "${pids[@]}"
check "throttled -> 429"       "$(curl -s -o /dev/null -w '%{http_code}' -H 'X-Upload-Token: bad' "$B/api/stats")" "429"
check "good token still works" "$(curl -s -H "$H" "$B/api/stats")" '"count":'

echo; echo "passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]]

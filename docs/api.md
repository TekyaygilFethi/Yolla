# API & internals

Yolla is one ASP.NET Core minimal‑API file (`src/Yolla/Program.cs`) and one static page (`src/Yolla/wwwroot/index.html`). No database.

## Upload flow

1. For each file the page computes `id = hash(name | size | lastModified | subfolder)` and asks `GET /api/exists`. If a file with the same name **and** size is on disk → skipped. If a partial `.yolla-<id>.part` exists → the answer says how many bytes are there and the upload resumes from that offset.
2. The file is sliced into `CHUNK_MB` pieces. Each is sent as a raw `PUT /api/upload` body and appended to the `.part` file. Kestrel streams the body straight into a `FileStream`; nothing is buffered in memory, so memory use stays flat regardless of file size.
3. When `received == size` the `.part` is renamed to its final unique name (`name (1).ext` on collision) and the original timestamp is restored from `mtime`.
4. Three files upload in parallel; each chunk retries with exponential back‑off; a `409` from the server (offset mismatch) re‑syncs the offset. Stale `.part` files older than 3 days are removed at startup and every 6 hours.

Because the id is derived from the file, resuming works after a page reload, a phone reboot, or a Yolla restart.

## Endpoints

All `/api/*` routes except `/api/config` require the token when `UPLOAD_TOKEN` is set: header `X-Upload-Token: …`, query `?token=…`, or the `yolla_token` cookie the page sets (`SameSite=Strict`, so it's never sent cross-site) — that last one is what lets download links work without a token in the URL.

| Method | Path | Query | Returns |
|---|---|---|---|
| GET | `/api/config` | – | `{ name, version, chunkBytes, maxBytes, tokenRequired, groupByDate }` (public) |
| GET | `/api/stats` | `album?` | `{ count, bytes }` for the folder |
| GET | `/api/recent` | `album?`, `n?` | latest uploads `[ { name, bytes, modified } ]` |
| GET | `/api/exists` | `name`, `size`, `mtime?`, `album?`, `id?` | `{ exists, partial }` |
| PUT | `/api/upload` | `name`, `size?`, `offset?`, `id?`, `mtime?`, `album?` | `{ done, received, saved? }` — body is the raw chunk |
| GET | `/api/outbox` | `path?` | `{ path, items: [ { name, dir, bytes, modified } ] }` — the Outbox only |
| GET | `/api/outbox/file` | `path`, `dl?` | the file (range requests supported; `dl=true` forces a download) |
| GET | `/api/outbox/zip` | `p` (repeat) | streamed ZIP of the given files/folders |
| GET | `/healthz` | – | `ok` |

`size` omitted → the whole file is expected in this one request (handy for scripts). `mtime` is Unix milliseconds. `album` is a subfolder name (sanitised; no traversal). With `GROUP_BY_DATE=true` files go under `YYYY/YYYY-MM/` derived from `mtime`.

### Examples

```bash
# whole file in one request
curl -T movie.mp4 "http://localhost:8080/api/upload?name=movie.mp4&token=mysecret"

# chunked by hand: 2 pieces of a 3.5 MB file
curl -X PUT --data-binary @part0 "http://localhost:8080/api/upload?name=a.bin&size=3500000&offset=0&id=abc123&token=mysecret"
curl -X PUT --data-binary @part1 "http://localhost:8080/api/upload?name=a.bin&size=3500000&offset=2000000&id=abc123&token=mysecret"

# what's already there?
curl "http://localhost:8080/api/exists?name=a.bin&size=3500000&id=abc123&token=mysecret"
```

## File naming & safety

- Names are reduced to their last path segment and stripped of characters Windows rejects (`<>:"/\|?*` and control characters), because the target is usually a Windows bind mount.
- Existing files are never overwritten; collisions get ` (1)`, ` (2)`, …
- Subfolder names are sanitised the same way and resolved inside `UPLOAD_DIR` only.
- Uploads are never served back. The only readable folder is `SHARE_DIR` (the Outbox); paths are resolved strictly inside it, hidden files are skipped. `/api/recent` returns names and sizes only. `SHARE_DIR=off` removes the read endpoints entirely.
- The token is compared in constant time; failed attempts are slowed down and, after 20 in a minute, answered with `429`.
- Every response carries `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` and `Referrer-Policy: no-referrer`; API responses are `Cache-Control: no-store`.
- `MAX_UPLOAD_MB` (optional) rejects files above a size you choose with `413`, both on the declared size and while streaming.

## Limits

- No request‑size limit in Kestrel (`MaxRequestBodySize = null`), no minimum data rate (slow mobile links are fine), 10 min keep‑alive.
- `CHUNK_MB` (default 32) is the chunk size; keep it under 100 with Cloudflare in front. `MAX_UPLOAD_MB` (default 0 = unlimited) caps single files.

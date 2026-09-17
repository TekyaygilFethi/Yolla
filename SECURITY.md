# Security

## Reporting a problem

If you think you've found a security issue, please don't open a public issue. Use GitHub's private
vulnerability reporting on this repository ("Security" tab → "Report a vulnerability"). You'll get a
reply within a few days, and a fix or a clear answer as fast as I can manage.

Only the latest release is supported.

## What Yolla does to stay safe

- **Uploads are write-only.** Nothing that was uploaded can be read back through Yolla. The only
  readable folder is the Outbox (`SHARE_DIR`) you fill on purpose; paths are resolved strictly inside it and
  `SHARE_DIR=off` removes the read endpoints. `/api/recent` returns names and sizes, nothing else.
- **Token.** Optional shared secret, compared in constant time. Failed attempts are slowed down and,
  after 20 in a minute, answered with `429`. The token can be sent as a header (what the page does) or
  as `?token=` for scripts, or as the `SameSite=Strict` cookie the page sets for download links; be aware that
  query strings can end up in proxy logs.
- **File names** are reduced to their last path segment and stripped of characters Windows rejects.
  Subfolder names get the same treatment and are resolved inside `UPLOAD_DIR` only. Existing files
  are never overwritten.
- **Container** runs as an unprivileged user (uid 1000 by default) and only sees the `/data` mount.
- **Headers:** `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`,
  `Cache-Control: no-store` on the API. No third-party scripts, fonts or analytics; the page makes no
  requests outside its own origin.
- **Optional cap:** `MAX_UPLOAD_MB` rejects single files above a size you choose.

## What it does not do

- It does not do TLS itself. Put it behind a tunnel or a reverse proxy for HTTPS (the README shows how).
- It does not stop someone who has the token from filling your disk. If you share the URL beyond your
  own devices, set `MAX_UPLOAD_MB` and consider Cloudflare Access in front.
- Running without a token on the public internet is unsupported and a bad idea.

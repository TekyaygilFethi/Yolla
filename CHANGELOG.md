# Changelog

## 1.0.0

- First release: upload photos, videos and any file from a phone or browser to a folder on your PC.
- Chunked, resumable uploads (32 MB chunks); duplicates skipped, collisions never overwritten, original timestamps kept.
- Optional access token, optional date-based subfolders, per-batch subfolder.
- Web UI in English and Turkish, light/dark, installable as a PWA, drag & drop and paste on desktop.
- One-line installers for Windows, macOS and Linux; Docker image for amd64 and arm64.
- Docker Compose profiles for Cloudflare Tunnel (quick and named) and ngrok; works behind any reverse proxy, including under a sub-path.
- Receive tab: an Outbox folder on the computer, browsable from the phone; single download, streamed ZIP, *Save to Photos* on iOS.
- Light/dark theme toggle; redesigned interface.
- Container runs unprivileged on an Alpine base; optional `MAX_UPLOAD_MB` cap; failed-token throttling; end-to-end smoke test in CI.

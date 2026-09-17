# Contributing

Thanks for helping! Yolla is deliberately small: one C# file, one HTML file, no dependencies. Please keep it that way.

## Run it locally

```bash
cd src/Yolla
UPLOAD_TOKEN=dev dotnet run          # http://localhost:8080, files go to ./uploads
```

Needs the [.NET 10 SDK](https://dotnet.microsoft.com/download). No Docker required for development.

## Guidelines

- **Bugs & ideas:** open an issue. Include your OS, browser (phone model + iOS/Android version if relevant) and how Yolla is exposed (LAN, Cloudflare, ngrok, reverse proxy).
- **Pull requests:** small and focused. If it needs a new NuGet package or a front-end framework, open an issue first — the answer is usually "let's find a way without it".
- **UI text:** every string lives in the `I18N` table in `wwwroot/index.html`; add both `en` and `tr` (or ask for a translation in the PR).
- **Testing:** `bash tests/smoke.sh` publishes the app, starts it and hits every endpoint with curl (chunking, resume, dedupe, size cap, throttling). It runs in CI; run it locally before a PR, and for anything touching the upload path please also try a real upload from a phone.
- **Scripts:** `bash -n scripts/install.sh` must pass; PowerShell changes should be tried on Windows PowerShell 5.1 *and* PowerShell 7.

## Releasing (maintainers)

Tag `vX.Y.Z` on `main`. The workflow builds the multi-arch image and publishes `ghcr.io/<owner>/yolla:X.Y.Z`, `:X.Y` and `:latest`. Update `CHANGELOG.md` and `<Version>` in `src/Yolla/Yolla.csproj` in the same commit.

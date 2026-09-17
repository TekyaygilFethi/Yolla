# iPhone: getting untouched originals

## What Safari does to your files

- **Photos** picked from the *Photos* library arrive as **JPEG**, converted from HEIC, at full resolution. It's a re‑encode (technically lossy), but not something you'll see; EXIF date and orientation are kept. If your camera is set to *Most Compatible* the photo is already JPEG and passes through as‑is.
- **Videos** picked from the *Photos* library are **re‑encoded by iOS** ("Compressing video…"): HEVC becomes H.264 at a lower bitrate. 4K/60 footage visibly loses detail, and in rare cases the audio track is dropped. This is iOS behaviour for every website; no page setting can switch it off.
- **Anything picked from the Files app** is uploaded **byte for byte**.

## Option 1 — Files app (a few videos)

1. In *Photos*, select the video → Share → **Save to Files** (e.g. *On My iPhone → Yolla*).
2. In Yolla tap **Any file (originals)** → *Choose File* → pick it from Files.

## Option 2 — a Shortcut (many videos, original HEIC photos, one tap)

Build once in the *Shortcuts* app:

1. **Select Photos** — turn on *Select Multiple*. (Add a *Videos* filter if you only want videos.)
2. **Repeat with Each** (over *Photos*)
3. inside the loop: **Get Name** of *Repeat Item*
4. inside the loop: **Get Contents of URL**
   - URL: `https://yolla.yourdomain.com/api/upload?name=[Name]&token=YOUR_TOKEN`
     (insert the *Name* variable from step 3)
   - Method: **PUT**
   - Request Body: **File** → *Repeat Item*
5. (optional, after the loop) **Show Notification** — "Done".

Run it, pick the items, done. Files arrive exactly as stored on the phone: original HEIC/HEVC, original names, no compression.

Notes:

- This path sends each file in a single request. Through **Cloudflare** that means a 100 MB per‑file limit (free plans); for bigger videos use ngrok, your LAN address, or the web page (which chunks).
- To set the file date correctly add **Get Details of Images → Date Taken**, format it as Unix milliseconds and append `&mtime=…` to the URL. Without it the file keeps its EXIF date but the file‑system timestamp is the upload time.
- If you set a **Subfolder** habit, append `&album=Holiday2026`.

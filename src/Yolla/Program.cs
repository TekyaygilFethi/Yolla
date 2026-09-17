// Yolla — send photos, videos and files from any phone or browser straight to a folder on your PC.
//
//   GET  /                 upload page (wwwroot/index.html)
//   GET  /api/config       public: chunk size, whether a token is required, version
//   GET  /api/stats        file count + total bytes in the target folder
//   GET  /api/recent       last N uploaded files
//   GET  /api/exists       does name+size already exist? how many bytes of a partial upload are on disk?
//   PUT  /api/upload       one chunk (or the whole file); body is raw bytes, streamed straight to disk
//   GET  /api/outbox       list the Outbox folder (the only folder that can be read back)
//   GET  /api/outbox/file  download / preview one Outbox file (range requests supported)
//   GET  /api/outbox/zip   several Outbox files as one streamed ZIP
//   GET  /healthz          liveness probe
//
// Everything is configured through environment variables — see README.md.

using System.Collections.Concurrent;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.StaticFiles;

// Published app: wwwroot sits next to Yolla.dll, so use that as content root no matter where it's started from.
// `dotnet run`: wwwroot is in the project directory (the default content root), so leave it alone.
var baseDir = AppContext.BaseDirectory;
var builder = Directory.Exists(Path.Combine(baseDir, "wwwroot"))
    ? WebApplication.CreateBuilder(new WebApplicationOptions { Args = args, ContentRootPath = baseDir })
    : WebApplication.CreateBuilder(args);

// Uploads are streamed, so Kestrel's body limit is off (MAX_UPLOAD_MB below is the knob users get instead).
// Be patient with slow mobile connections.
builder.WebHost.ConfigureKestrel(o =>
{
    o.Limits.MaxRequestBodySize = null;
    o.Limits.MinRequestBodyDataRate = null;
    o.Limits.KeepAliveTimeout = TimeSpan.FromMinutes(10);
    o.Limits.RequestHeadersTimeout = TimeSpan.FromMinutes(2);
});
builder.Logging.AddFilter("Microsoft.AspNetCore", LogLevel.Warning);

var app = builder.Build();

// ---- configuration -------------------------------------------------------------------------

static string? Env(string name) => Environment.GetEnvironmentVariable(name) is { Length: > 0 } v ? v : null;
static bool EnvFlag(string name) => Env(name) is "1" or "true" or "yes";
static int EnvInt(string name, int fallback, int min = 0) => int.TryParse(Env(name), out var v) && v >= min ? v : fallback;

var inContainer = Env("DOTNET_RUNNING_IN_CONTAINER") is "true";
var root        = Path.GetFullPath(Env("UPLOAD_DIR") ?? (inContainer ? "/data" : "uploads"));
var token       = Env("UPLOAD_TOKEN");
var groupByDate = EnvFlag("GROUP_BY_DATE");
var chunkMb     = EnvInt("CHUNK_MB", 32, min: 1);
var maxUploadMb = EnvInt("MAX_UPLOAD_MB", 0);            // 0 = unlimited
var version     = typeof(Program).Assembly.GetName().Version?.ToString(3) ?? "dev";
var maxBytes    = maxUploadMb > 0 ? maxUploadMb * 1024L * 1024L : long.MaxValue;

// The Outbox is the one folder the phone may read: drop files there on the PC, pick them up on the phone.
// Default: an "Outbox" folder inside the upload folder. SHARE_DIR=off disables the Receive tab entirely.
var shareCfg = Env("SHARE_DIR");
var share    = string.Equals(shareCfg, "off", StringComparison.OrdinalIgnoreCase) ? null
             : Path.GetFullPath(shareCfg ?? Path.Combine(root, "Outbox"));
var shareInsideRoot = share is not null && share.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.Ordinal);
var excludeFromUploads = shareInsideRoot ? share : null;

Directory.CreateDirectory(root);
if (share is not null) { try { Directory.CreateDirectory(share); } catch (Exception e) { app.Logger.LogWarning("Outbox {Share} not available: {Error}", share, e.Message); share = null; } }
try { File.Delete(Path.Combine(root, ".yolla-write-test")); File.WriteAllText(Path.Combine(root, ".yolla-write-test"), ""); File.Delete(Path.Combine(root, ".yolla-write-test")); }
catch (Exception e) { app.Logger.LogCritical("Cannot write to {Root}: {Error}. Check the folder's permissions (PUID/PGID in Docker).", root, e.Message); return 1; }

app.Logger.LogInformation("Yolla {Version} — folder: {Root} | outbox: {Share} | token: {Token} | group by date: {Group} | chunk: {Chunk} MB | max file: {Max}",
    version, root, share ?? "off", token is null ? "OFF (anyone with the URL can upload!)" : "on", groupByDate, chunkMb, maxUploadMb > 0 ? $"{maxUploadMb} MB" : "unlimited");

// Abandoned partial uploads are removed after 3 days — at startup and every 6 hours.
CleanupStaleParts(root, TimeSpan.FromDays(3));
_ = Task.Run(async () =>
{
    using var timer = new PeriodicTimer(TimeSpan.FromHours(6));
    while (await timer.WaitForNextTickAsync()) CleanupStaleParts(root, TimeSpan.FromDays(3));
});

// ---- auth (optional) -----------------------------------------------------------------------
// Constant-time comparison, plus a small global brake on failed attempts so a leaked URL can't be
// brute-forced quickly (a 20+ character random token is out of reach anyway).

var authFailures = 0; var authWindow = DateTime.UtcNow;
app.Use(async (ctx, next) =>
{
    ctx.Response.Headers["X-Content-Type-Options"] = "nosniff";
    ctx.Response.Headers["X-Frame-Options"] = "DENY";
    ctx.Response.Headers["Referrer-Policy"] = "no-referrer";

    var path = ctx.Request.Path;
    if (token is not null && path.StartsWithSegments("/api") && !path.StartsWithSegments("/api/config"))
    {
        var given = ctx.Request.Headers["X-Upload-Token"].FirstOrDefault()
                    ?? ctx.Request.Query["token"].FirstOrDefault()
                    ?? ctx.Request.Cookies["yolla_token"]
                    ?? "";
        if (!FixedTimeEquals(given, token))
        {
            if (DateTime.UtcNow - authWindow > TimeSpan.FromMinutes(1)) { authWindow = DateTime.UtcNow; authFailures = 0; }
            var n = Interlocked.Increment(ref authFailures);
            await Task.Delay(n > 20 ? 5000 : 500, ctx.RequestAborted);
            ctx.Response.StatusCode = n > 20 ? StatusCodes.Status429TooManyRequests : StatusCodes.Status401Unauthorized;
            await ctx.Response.WriteAsJsonAsync(new { error = n > 20 ? "too many failed attempts" : "unauthorized" });
            return;
        }
    }
    if (path.StartsWithSegments("/api")) ctx.Response.Headers["Cache-Control"] = "no-store";
    await next();
});

app.UseDefaultFiles();
app.UseStaticFiles();

// ---- endpoints -----------------------------------------------------------------------------

app.MapGet("/healthz", () => Results.Text("ok"));

app.MapGet("/api/config", () => new
{
    name = "Yolla",
    version,
    chunkBytes = (long)chunkMb * 1024 * 1024,
    maxBytes = maxUploadMb > 0 ? maxBytes : 0,
    tokenRequired = token is not null,
    groupByDate,
    outbox = share is not null,
    outboxPath = share is null ? null : shareInsideRoot ? Path.GetRelativePath(root, share) : share,
});

// Folder statistics are O(files), so cache them briefly — the page asks after every batch.
var statsCache = new ConcurrentDictionary<string, (DateTime at, int count, long bytes)>();
app.MapGet("/api/stats", (string? album) =>
{
    var dir = AlbumDir(root, album);
    if (statsCache.TryGetValue(dir, out var c) && DateTime.UtcNow - c.at < TimeSpan.FromSeconds(10))
        return Results.Ok(new { c.count, c.bytes });
    long bytes = 0; var count = 0;
    if (Directory.Exists(dir)) foreach (var f in EnumerateUploads(dir, excludeFromUploads)) { count++; bytes += f.Length; }
    statsCache[dir] = (DateTime.UtcNow, count, bytes);
    return Results.Ok(new { count, bytes });
});

// Files saved by this process, newest first (falls back to the folder listing after a restart).
var recent = new ConcurrentQueue<RecentItem>();
app.MapGet("/api/recent", (string? album, int? n) =>
{
    var dir = AlbumDir(root, album);
    var take = Math.Clamp(n ?? 20, 1, 200);
    var prefix = dir == root ? "" : Path.GetRelativePath(root, dir).Replace('\\', '/') + "/";
    var mem = recent.Reverse().Where(r => r.Path.StartsWith(prefix, StringComparison.Ordinal))
        .Select(r => new { name = r.Path[prefix.Length..], bytes = r.Bytes, modified = r.At }).Take(take).ToList();
    if (mem.Count > 0 || !Directory.Exists(dir)) return Results.Ok(mem);
    var disk = EnumerateUploads(dir, excludeFromUploads).OrderByDescending(f => f.LastWriteTimeUtc).Take(take)
        .Select(f => new { name = Path.GetRelativePath(dir, f.FullName).Replace('\\', '/'), bytes = f.Length, modified = f.LastWriteTimeUtc });
    return Results.Ok(disk);
});

// Client asks before uploading: skip if identical name+size exists; resume if a partial exists.
app.MapGet("/api/exists", (string name, long size, long? mtime, string? album, string? id) =>
{
    var dir = TargetDir(root, album, mtime, groupByDate);
    var final = Path.Combine(dir, SafeName(name));
    var exists = File.Exists(final) && new FileInfo(final).Length == size;
    long partial = 0;
    if (!exists && SafeId(id) is { } sid)
    {
        var part = PartPath(dir, sid);
        if (File.Exists(part)) partial = new FileInfo(part).Length;
    }
    return Results.Ok(new { exists, partial });
});

// One chunk. size+offset+id => chunked/resumable. Without size => whole file in one request (curl-friendly).
app.MapPut("/api/upload", async (HttpRequest req, string name, long? size, long? offset, string? id, long? mtime, string? album, CancellationToken ct) =>
{
    var off = offset ?? 0;
    if (off < 0 || (size is { } s0 && (s0 < 0 || off > s0))) return Results.BadRequest(new { error = "bad offset/size" });
    if ((size ?? req.ContentLength ?? 0) > maxBytes) return Results.Json(new { error = $"file larger than MAX_UPLOAD_MB ({maxUploadMb} MB)" }, statusCode: StatusCodes.Status413PayloadTooLarge);

    var dir = TargetDir(root, album, mtime, groupByDate);
    Directory.CreateDirectory(dir);
    var sid  = SafeId(id) ?? Guid.NewGuid().ToString("N");
    var part = PartPath(dir, sid);

    long received;
    try
    {
        await using (var fs = new FileStream(part, FileMode.OpenOrCreate, FileAccess.Write, FileShare.None, 1 << 20, useAsync: true))
        {
            if (fs.Length != off)
                return Results.Json(new { error = "offset mismatch", received = fs.Length }, statusCode: StatusCodes.Status409Conflict);
            fs.Seek(off, SeekOrigin.Begin);
            await CopyBoundedAsync(req.Body, fs, maxBytes - off, ct);
            received = fs.Length;
        }
    }
    catch (OperationCanceledException)
    {
        // Client went away mid-chunk. Keep what we have; the client will resume from `partial`.
        return Results.StatusCode(499);
    }
    catch (InvalidDataException)
    {
        File.Delete(part);
        return Results.Json(new { error = $"file larger than MAX_UPLOAD_MB ({maxUploadMb} MB)" }, statusCode: StatusCodes.Status413PayloadTooLarge);
    }

    if (size is { } total && received > total)
    {
        File.Delete(part);
        return Results.BadRequest(new { error = "received more than declared size" });
    }
    if (size is { } t && received < t)
        return Results.Ok(new { done = false, received });

    // Complete: move into place under a unique name (retry if two same-named files finish at once),
    // then restore the original timestamp.
    string final;
    for (var attempt = 0; ; attempt++)
    {
        final = UniquePath(dir, SafeName(name));
        try { File.Move(part, final, overwrite: false); break; }
        catch (IOException) when (attempt < 5 && File.Exists(final)) { }
    }
    if (mtime is > 0)
    {
        var ts = DateTimeOffset.FromUnixTimeMilliseconds(mtime.Value).UtcDateTime;
        try { File.SetLastWriteTimeUtc(final, ts); File.SetCreationTimeUtc(final, ts); } catch { /* some mounts refuse */ }
    }
    var rel = Path.GetRelativePath(root, final).Replace('\\', '/');
    recent.Enqueue(new RecentItem(rel, received, DateTime.UtcNow));
    while (recent.Count > 500) recent.TryDequeue(out _);
    statsCache.Clear();
    app.Logger.LogInformation("saved {File} ({Bytes:N0} bytes)", rel, received);
    return Results.Ok(new { done = true, received, saved = rel });
});

// ---- Outbox (PC -> phone) ------------------------------------------------------------------

var mime = new FileExtensionContentTypeProvider();

app.MapGet("/api/outbox", (string? path) =>
{
    if (share is null) return Results.NotFound(new { error = "outbox disabled" });
    var dir = ResolveInside(share, path);
    if (dir is null || !Directory.Exists(dir)) return Results.NotFound(new { error = "no such folder" });
    var di = new DirectoryInfo(dir);
    var folders = di.EnumerateDirectories().Where(d => !d.Name.StartsWith('.')).OrderBy(d => d.Name, StringComparer.OrdinalIgnoreCase)
        .Select(d => new { name = d.Name, dir = true, bytes = 0L, modified = d.LastWriteTimeUtc });
    var files = di.EnumerateFiles().Where(f => !f.Name.StartsWith('.') && !f.Name.EndsWith(".part")).OrderByDescending(f => f.LastWriteTimeUtc)
        .Select(f => new { name = f.Name, dir = false, bytes = f.Length, modified = f.LastWriteTimeUtc });
    return Results.Ok(new { path = Path.GetRelativePath(share, dir) is "." ? "" : Path.GetRelativePath(share, dir).Replace('\\', '/'), items = folders.Concat(files) });
});

app.MapGet("/api/outbox/file", (string path, bool? dl) =>
{
    if (share is null) return Results.NotFound();
    var file = ResolveInside(share, path);
    if (file is null || !File.Exists(file) || Path.GetFileName(file).StartsWith('.')) return Results.NotFound();
    var type = mime.TryGetContentType(file, out var t) ? t : "application/octet-stream";
    return Results.File(file, type, dl is true ? Path.GetFileName(file) : null, enableRangeProcessing: true);
});

// Streams the ZIP straight to the response; nothing is buffered. Folders are included recursively.
app.MapGet("/api/outbox/zip", async (HttpContext ctx, string[] p) =>
{
    if (share is null) { ctx.Response.StatusCode = 404; return; }
    var files = new List<string>();
    foreach (var raw in p)
    {
        var full = ResolveInside(share, raw);
        if (full is null) continue;
        if (File.Exists(full)) files.Add(full);
        else if (Directory.Exists(full)) files.AddRange(Directory.EnumerateFiles(full, "*", SearchOption.AllDirectories));
    }
    files = files.Where(f => !Path.GetFileName(f).StartsWith('.') && !f.EndsWith(".part")).Distinct().ToList();
    if (files.Count == 0) { ctx.Response.StatusCode = 404; return; }
    ctx.Response.ContentType = "application/zip";
    ctx.Response.Headers.ContentDisposition = $"attachment; filename=\"yolla-{DateTime.Now:yyyyMMdd-HHmm}.zip\"";
    // ZipArchive writes its small headers synchronously; Kestrel forbids that unless told otherwise.
    var bodyControl = ctx.Features.Get<Microsoft.AspNetCore.Http.Features.IHttpBodyControlFeature>();
    if (bodyControl is not null) bodyControl.AllowSynchronousIO = true;
    using var zip = new ZipArchive(ctx.Response.Body, ZipArchiveMode.Create, leaveOpen: true);
    foreach (var f in files)
    {
        var entry = zip.CreateEntry(Path.GetRelativePath(share, f).Replace('\\', '/'), CompressionLevel.NoCompression);
        entry.LastWriteTime = File.GetLastWriteTime(f);
        await using var es = entry.Open();
        await using var fs = new FileStream(f, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 16, useAsync: true);
        await fs.CopyToAsync(es, ctx.RequestAborted);
    }
});

app.Run();
return 0;

// ---- helpers -------------------------------------------------------------------------------

static bool FixedTimeEquals(string a, string b)
{
    var x = Encoding.UTF8.GetBytes(a); var y = Encoding.UTF8.GetBytes(b);
    return x.Length == y.Length && CryptographicOperations.FixedTimeEquals(x, y);
}

// Stream the body to disk without buffering; stop (and fail) if it exceeds the remaining allowance.
static async Task CopyBoundedAsync(Stream from, Stream to, long allowance, CancellationToken ct)
{
    var buf = new byte[1 << 16];
    long total = 0;
    int n;
    while ((n = await from.ReadAsync(buf, ct)) > 0)
    {
        total += n;
        if (total > allowance) throw new InvalidDataException("upload exceeds MAX_UPLOAD_MB");
        await to.WriteAsync(buf.AsMemory(0, n), ct);
    }
}

// The target folder is usually a Windows bind mount, so strip Windows-invalid characters too.
static string SafeName(string name)
{
    name = name.Trim();
    var slash = name.LastIndexOfAny(['/', '\\']);
    if (slash >= 0) name = name[(slash + 1)..];
    var sb = new StringBuilder(name.Length);
    foreach (var c in name) sb.Append(c < 32 || "<>:\"/\\|?*".Contains(c) ? '_' : c);
    var s = sb.ToString().TrimEnd('.', ' ');
    if (s.Length > 200) s = s[..200];
    return string.IsNullOrWhiteSpace(s) || s.StartsWith(".yolla-") ? "file" + s : s;
}

// A user-supplied relative path, resolved strictly inside `baseDir` (or null if it escapes).
static string? ResolveInside(string baseDir, string? rel)
{
    rel = (rel ?? "").Replace('\\', '/').Trim('/');
    if (rel.Length == 0) return baseDir;
    var full = Path.GetFullPath(Path.Combine(baseDir, rel));
    return full == baseDir || full.StartsWith(baseDir + Path.DirectorySeparatorChar, StringComparison.Ordinal) ? full : null;
}

static string? SafeId(string? id) => id is not null && Regex.IsMatch(id, "^[A-Za-z0-9]{1,40}$") ? id : null;

static string PartPath(string dir, string id) => Path.Combine(dir, $".yolla-{id}.part");

static string AlbumDir(string root, string? album)
{
    if (string.IsNullOrWhiteSpace(album)) return root;
    var a = SafeName(album).Replace("..", "_");
    var full = Path.GetFullPath(Path.Combine(root, a));
    return full.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.Ordinal) ? full : root;
}

static string TargetDir(string root, string? album, long? mtime, bool groupByDate)
{
    var dir = AlbumDir(root, album);
    if (!groupByDate) return dir;
    var d = mtime is > 0 ? DateTimeOffset.FromUnixTimeMilliseconds(mtime.Value).UtcDateTime : DateTime.UtcNow;
    return Path.Combine(dir, d.ToString("yyyy"), d.ToString("yyyy-MM"));
}

// "IMG_0001.JPG" already there but different? -> "IMG_0001 (1).JPG". Never overwrite.
static string UniquePath(string dir, string name)
{
    var path = Path.Combine(dir, name);
    if (!File.Exists(path)) return path;
    var stem = Path.GetFileNameWithoutExtension(name);
    var ext = Path.GetExtension(name);
    for (var i = 1; ; i++)
    {
        var p = Path.Combine(dir, $"{stem} ({i}){ext}");
        if (!File.Exists(p)) return p;
    }
}

static IEnumerable<FileInfo> EnumerateUploads(string dir, string? exclude) =>
    new DirectoryInfo(dir).EnumerateFiles("*", SearchOption.AllDirectories)
        .Where(f => !f.Name.EndsWith(".part") && (exclude is null || !f.FullName.StartsWith(exclude + Path.DirectorySeparatorChar, StringComparison.Ordinal)));

static void CleanupStaleParts(string root, TimeSpan olderThan)
{
    try
    {
        var cutoff = DateTime.UtcNow - olderThan;
        foreach (var f in new DirectoryInfo(root).EnumerateFiles(".yolla-*.part", SearchOption.AllDirectories))
            if (f.LastWriteTimeUtc < cutoff) { try { f.Delete(); } catch { } }
    }
    catch { }
}

record RecentItem(string Path, long Bytes, DateTime At);

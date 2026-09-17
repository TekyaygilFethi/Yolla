# Your own reverse proxy (optional)

Yolla is a plain HTTP server on port 8080. If you have a public IP and a domain you don't need a tunnel: forward 443 to your proxy and proxy to Yolla. Yolla never generates absolute URLs, so it also works under a sub‑path (`https://home.example.com/yolla/`) as long as the proxy strips the prefix.

Two settings matter, because uploads arrive as 32 MB chunks:

1. the proxy's **request body size limit** (nginx defaults to 1 MB → every chunk fails with 413);
2. **request buffering** — streaming straight through avoids the proxy writing each chunk to a temp file first.

If the proxy runs on the same machine, bind Yolla to localhost so port 8080 isn't reachable from outside: `YOLLA_BIND=127.0.0.1` in `.env`, or `-p 127.0.0.1:8080:8080` with `docker run`. Yolla doesn't need `X-Forwarded-*` headers (it never builds absolute URLs), but passing them is harmless.

## Caddy

Nothing to configure; HTTPS is automatic.

```caddyfile
yolla.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

## nginx

```nginx
server {
    listen 443 ssl http2;
    server_name yolla.example.com;
    # ssl_certificate / ssl_certificate_key from certbot

    client_max_body_size 0;               # default 1 MB -> 413 on every chunk
    location / {                          # sub-path:  location /yolla/ { proxy_pass http://127.0.0.1:8080/; ... }
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_request_buffering off;      # stream chunks straight to Yolla
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Traefik (compose labels)

```yaml
services:
  yolla:
    image: ghcr.io/tekyaygilfethi/yolla:latest
    labels:
      - traefik.enable=true
      - traefik.http.routers.yolla.rule=Host(`yolla.example.com`)
      - traefik.http.routers.yolla.entrypoints=websecure
      - traefik.http.routers.yolla.tls.certresolver=letsencrypt
      - traefik.http.services.yolla.loadbalancer.server.port=8080
```

Traefik has no request‑body limit by default and streams requests. Don't add a `buffering` middleware.

## Nginx Proxy Manager

Add a proxy host pointing to `yolla:8080` (same Docker network) or `<host-ip>:8080`, enable SSL. In the host's *Advanced* tab add:

```nginx
client_max_body_size 0;
proxy_request_buffering off;
proxy_read_timeout 300s;
proxy_send_timeout 300s;
```

## Cloudflare DNS proxy (orange cloud) without a tunnel

Works, with the same 100 MB per‑request limit as the tunnel — the chunking takes care of it. Keep `CHUNK_MB` under 100.

## Tailscale

If both devices are on your tailnet, open `http://<pc-tailscale-ip>:8080` from anywhere; no tunnel or proxy needed. `tailscale serve` adds HTTPS, `tailscale funnel` publishes it to the internet. The trade‑off: the Tailscale app must be on the phone.

# Backend Deployment Runbook

This document is the handoff guide for deploying the FastAPI middleware. Replace every example value such as `api.example.com` before production use.

## 1. Deployment topology

Recommended topology:

```text
Flutter mobile/web -> https://api.example.com/api/v1
					|
				HTTPS reverse proxy :443
					|
				FastAPI container :8000
					|
				Odoo RPC server
```

Expose only ports `80` and `443` publicly. Keep FastAPI port `8000` private to the host or container network.

## 2. Prerequisites

- A Linux server or container platform with Docker installed.
- A DNS A/AAAA record such as `api.example.com` pointing to the server.
- A valid TLS certificate for the API domain.
- Network access from the server to the Odoo host and port.
- Production values stored in the platform secret manager.

## 3. Environment and secrets

Use [.env.example](.env.example) as the variable checklist. Do not copy development `.env` values into production and do not commit a production `.env` file.

Required values:

```env
APP_ENV=production
ODOO_HOST=your-odoo-host.example.com
ODOO_DB=your_odoo_database
ODOO_SCHEME=https
ODOO_PORT=443
ODOO_ADMIN_USER=admin
ODOO_ADMIN_PASS=<secret>
JWT_SECRET_KEY=<at-least-32-random-characters>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_DAYS=1
CORS_ALLOW_ORIGINS=https://app.example.com
```

Use an empty `CORS_ALLOW_ORIGINS` for mobile-only clients. For multiple browser origins, separate them with commas. Rotate the JWT secret before the first production release; rotating it invalidates existing sessions.

## 4. Build and run with Docker

Run from this directory:

```bash
docker build --tag sekolah-middleware:production .
docker run --detach \
  --name sekolah-middleware \
  --restart unless-stopped \
  --publish 127.0.0.1:8000:8000 \
  --env-file .env \
  sekolah-middleware:production
```

The image starts Uvicorn without `--reload`. Do not publish port `8000` directly to the public internet when a reverse proxy is available.

## 5. DNS and HTTPS reverse proxy

Create this DNS record:

```text
api.example.com -> <server-public-ip>
```

Example Nginx server block after installing a TLS certificate:

```nginx
server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /etc/letsencrypt/live/api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;

    location / {
	   proxy_pass http://127.0.0.1:8000;
	   proxy_set_header Host $host;
	   proxy_set_header X-Real-IP $remote_addr;
	   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	   proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Redirect HTTP to HTTPS and renew the certificate automatically with the platform or Certbot.

## 6. Deployment verification

Run these checks after starting the container and after configuring the domain:

```bash
curl --fail https://api.example.com/
curl --fail https://api.example.com/health/live
curl --fail https://api.example.com/health/ready
docker logs --tail 100 sekolah-middleware
```

Expected results:

- `/health/live` returns HTTP `200` with `{"status":"ok"}`.
- `/health/ready` returns HTTP `200` only when the Odoo host and port are reachable.
- The container remains running without a restart loop.

Configure `/health/live` as the liveness probe and `/health/ready` as the readiness probe.

## 7. Flutter configuration

Build the mobile application against the HTTPS API domain, not a LAN IP or HTTP URL:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Upload the resulting `build/app/outputs/bundle/release/app-release.aab` to Google Play. Existing app users must log in again after the production auth format change.

## 8. Rollback

Keep the previous image tag available. To roll back:

```bash
docker stop sekolah-middleware
docker rm sekolah-middleware
docker run --detach --name sekolah-middleware --restart unless-stopped \
  --publish 127.0.0.1:8000:8000 --env-file .env \
  sekolah-middleware:<previous-tag>
```

Verify `/health/live`, `/health/ready`, and a real login flow after rollback.

## 9. Important security notes

- Never commit `.env`, keystores, JWT secrets, or Odoo passwords.
- Use HTTPS for the public API and for Odoo whenever supported.
- Restrict firewall access to ports `80` and `443`.
- Do not use `uvicorn --reload` in production.
- The new auth format encrypts the Odoo password inside the signed JWT. Tokens issued by older versions must be replaced by logging in again.

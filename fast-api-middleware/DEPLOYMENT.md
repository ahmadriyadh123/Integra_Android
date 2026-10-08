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
- Network access from the server to each Odoo instance registered for a school.
- Production values stored in the platform secret manager.

## 3. Environment and secrets

Use [.env.example](.env.example) as the variable checklist. Do not copy development `.env` values into production and do not commit a production `.env` file.

Required values:

```env
APP_ENV=production
JWT_SECRET_KEY=<at-least-32-random-characters>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_DAYS=1
CORS_ALLOW_ORIGINS=https://app.example.com,https://school-admin.example.com
SCHOOL_ADMIN_USERNAME=<initial-admin-username>
SCHOOL_ADMIN_PASSWORD=<initial-admin-password-at-least-12-characters>
```

Each school's Odoo URL and database name are configured in the middleware's
`school_tenants` registry (through the school admin interface). API requests
select the tenant with `X-School-ID`; Odoo features use that tenant's URL and
database. There is no global Odoo host/database fallback in the environment.

On first startup, these two variables bootstrap the first record in the
`school_admin_accounts` table. The backend stores a salted PBKDF2-SHA256
password hash and checks subsequent logins against the database; it does not
compare login credentials with the environment variables. Bootstrap values do
not overwrite an existing account. Keep both values available only until the
initial account has been created, then remove the password from the deployment
environment/secret configuration. Back up the registry database and restrict
database access because it contains the admin password hashes.

The middleware calls Odoo using the authenticated student's UID and password.
Grant student groups only the ACL and record-rule access required for their own
records, including the assignment submission and attachment operations used by
the application. Keep unlink access disabled unless explicitly required.

Use an empty `CORS_ALLOW_ORIGINS` for mobile-only clients. For multiple browser origins, separate them with commas. Rotate the JWT secret before the first production release; rotating it invalidates existing sessions.
When hosting `school-admin-web` separately, add its exact HTTPS origin to
`CORS_ALLOW_ORIGINS` so its credentialed requests can use the admin session
cookie. Keep the web app and API on the same site (for example, sibling
subdomains) so the browser accepts the `SameSite=Strict` cookie.

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
- `/health/ready` returns HTTP `200` when the middleware's tenant-registry
  database is reachable. Odoo connectivity is specific to each registered
  school and is exercised by that school's authenticated API requests.
- The container remains running without a restart loop.

Configure `/health/live` as the liveness probe and `/health/ready` as the readiness probe.

## 7. Flutter configuration

Build the mobile application against the HTTPS API domain, not a LAN IP or HTTP URL:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com/api/v1 --dart-define=SCHOOL_ID=1
```

`SCHOOL_ID` must match the tenant row's `id` in the middleware `school_tenants` table. The app also accepts this ID on the login screen and saves it on the device.

The login screen does not ask for the API address. For Android/iOS builds, set `API_BASE_URL` to the middleware address for that build; use a stable API domain so moving the backend only requires changing DNS or the reverse-proxy target. Flutter Web defaults to the current origin plus `/api/v1` when `API_BASE_URL` is omitted.

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

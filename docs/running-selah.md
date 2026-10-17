# Running Selah (server)

This page is for the person who keeps the server. Members should use [using-selah.md](using-selah.md).

## What runs where

- **Mail host:** sends sign-in codes (SMTP, usually port 587).
- **VPS (Docker):** containers `selah-api` and `selah-postgres`.
- **Public address:** your HTTPS hostname (set as `PUBLIC_BASE_URL` in `.env` on the VPS only — not in git).

Do not open Postgres to the internet. The phones and the church page talk only to the API.

## First start

1. On the VPS, copy `server/.env.example` to `server/.env` and fill in passwords, `TOKEN_SECRET`, SMTP, and `PUBLIC_BASE_URL` (your real hostname). Any database password is fine; the API does not embed it in a URL.
2. Confirm port **8091** is free (`docker ps` and `ss -lntp`). If it is taken, set `SELAH_API_HOST_PORT` to the next free port in 8091–8099.
3. Set `SELAH_PROXY_NETWORK` to the Docker network your reverse proxy already uses, or remove the `proxy_net` entry from `docker-compose.yml` if you terminate TLS another way.
4. From the `server/` folder:

```bash
docker compose up -d --build
```

5. Point your reverse proxy at the API. Example Caddy site block (replace the hostname):

```
your-selah-host.example {
	encode gzip
	reverse_proxy selah-api:8080
}
```

   The proxy container must share a Docker network with `selah-api` (see `SELAH_PROXY_NETWORK`), or proxy to `127.0.0.1:8091` on the host if that fits your setup.
6. Open `https://your-selah-host.example/api/health` and confirm `{"ok":true}`.
7. Request a sign-in code from the app or the website and confirm the email arrives.

Containers must stay named `selah-api` and `selah-postgres` so they do not clash with other stacks on the same host. Do not publish host port 5432 for Selah if something else already uses it.

## Daily backup

Prayers are pastoral. Keep backups private.

```bash
docker exec selah-postgres pg_dump -U selah selah > selah-$(date +%F).sql
```

Copy the dump off the VPS to a private place.

## Appoint a new group owner

When the owner leaves or can no longer open their email:

```bash
docker exec -it selah-api node scripts/appoint-owner.js \
  --group-id <group-uuid> \
  --email new-owner@example.com
```

Find the group id in the database if needed:

```bash
docker exec -it selah-postgres psql -U selah -d selah \
  -c "SELECT id, name, invite_code FROM groups;"
```

The new owner may already belong to another group. The command adds them to this group if needed and makes them owner. Only one owner remains for that group. This is not available in the app or on the public website.

## GitHub Actions deploy

Pushes to `master` that change `server/` (or a manual **Run workflow**) SSH in and rebuild the containers. Workflow: [`.github/workflows/deploy-server.yml`](../.github/workflows/deploy-server.yml).

Repository secrets:

| Secret | Value |
|--------|---------|
| `VPS_HOST` | VPS host |
| `VPS_USER` | Deploy SSH user |
| `VPS_SSH_KEY` | Deploy private key |
| `VPS_PORT` | SSH port |

Keep `server/.env` only on the VPS. Actions does not upload it. The deploy job hard-resets the checkout to `origin/master` (`.env` is gitignored and stays).

The checkout path on the VPS must be able to `git fetch` as the deploy user (see the workflow for the path it uses).

## App build

Pass your API base URL at build time (required for group sync):

```bash
flutter run --dart-define=SELAH_API_BASE_URL=https://your-selah-host.example
```

Google Sheet sync is no longer used.

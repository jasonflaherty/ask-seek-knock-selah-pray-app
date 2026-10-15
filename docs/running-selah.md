# Running Selah (server)

This page is for the person who keeps the VPS. Members should use [using-selah.md](using-selah.md).

## What runs where

- **Shared hosting (Nixihost / cPanel):** website and the mailbox that sends sign-in codes.
- **Unmanaged VPS:** Docker containers `selah-api` and `selah-postgres`.
- **Public address:** `https://selah.psithurismlabs.com` (A record already pointed at the VPS).

Do not open Postgres to the internet. The phones and the church page talk only to the API.

## First start

1. On the VPS, copy `server/.env.example` to `server/.env` and fill in passwords, `TOKEN_SECRET`, and SMTP settings for the Nixihost mailbox (port 587). Any password is fine; the API no longer embeds it in a URL.
2. Confirm port **8091** is free (`docker ps` and `ss -lntp`). If it is taken, set `SELAH_API_HOST_PORT` to the next free port in 8091–8099.
3. From the `server/` folder:

```bash
docker compose up -d --build
```

4. HTTPS uses the existing Caddy container (`son-caddy-1`), not a second Caddy.
   - `selah-api` joins the external Docker network `son_default` (see `docker-compose.yml`).
   - In `/opt/son/deploy/Caddyfile` add:

```
selah.psithurismlabs.com {
	encode gzip
	reverse_proxy selah-api:8080
}
```

   - Then: `docker exec son-caddy-1 caddy reload --config /etc/caddy/Caddyfile`
5. Open `https://selah.psithurismlabs.com/api/health` and confirm `{"ok":true}`.
6. Request a sign-in code from the app or the website and confirm the email arrives.

Containers must stay named `selah-api` and `selah-postgres` so they do not clash with existing `api` and `mcda` containers. Do not publish host port 5432 for Selah (mcda already uses it).

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

The new owner must already be a member, or the command adds them and makes them owner. Only one owner remains. This is not available in the app or on the public website.

## GitHub Actions deploy

Pushes to `master` that change `server/` (or a manual **Run workflow**) SSH in as `selahdeploy` and rebuild the containers. Workflow: [`.github/workflows/deploy-server.yml`](../.github/workflows/deploy-server.yml).

Repository secrets (already set):

| Secret | Value |
|--------|---------|
| `VPS_HOST` | VPS host |
| `VPS_USER` | `selahdeploy` |
| `VPS_SSH_KEY` | Private key from `~/.ssh/selah_vps_deploy` |
| `VPS_PORT` | SSH port |

Keep `server/.env` only on the VPS. Actions does not upload it. The deploy job hard-resets `/opt/selah` to `origin/master` (`.env` is gitignored and stays).

On the VPS, `/opt/selah` must be a git checkout that can `git fetch` as `selahdeploy`.

## App build

Build the Flutter app with the API URL:

```bash
flutter run --dart-define=SELAH_API_BASE_URL=https://selah.psithurismlabs.com
```

Google Sheet sync is no longer used.

# saftaja | سفتجة

Self-hostable, open-source payments on top of MPGS (Mastercard Payment Gateway
Services), the gateway most Gulf banks hand to merchants. Saftaja gives you hosted
checkout pages with 3-D Secure, per-merchant custom domains with automatic TLS, and a
dashboard, so you don't have to integrate MPGS by hand.

> **Status:** pre-release. Card payments with 3DS work end to end. The merchant API,
> webhooks and Apple Pay are in progress.

## Repo layout

| Path      | What                                                        |
| --------- | ----------------------------------------------------------- |
| `khazina` | Go backend: payments, hosted checkout, dashboard API        |
| `diwan`   | Merchant dashboard (React + Vite)                           |
| `bawaba`  | Landing page                                                |
| `proto`   | Dashboard API definitions (Connect RPC), generated with buf |
| `infra`   | Server provisioning                                         |

## Getting started

You need [OrbStack](https://orbstack.dev) (or any Docker runtime) and
[mise](https://mise.jdx.dev). mise installs everything else (Go, Bun, buf).

```bash
mise install
cp .env.example .env
```

Fill in the secrets in `.env`:

```bash
openssl rand -base64 32                     # ENCRYPTION_KEY
openssl rand -hex 16                        # VERIFY_DOMAIN_SECRET
openssl genrsa 2048 | base64 | tr -d '\n'   # JWT_PRIVATE_KEY
```

Then start everything with hot reload:

```bash
mise run dev
```

| Service   | URL                   |
| --------- | --------------------- |
| khazina   | http://localhost:8080 |
| diwan     | http://localhost:5173 |
| bawaba    | http://localhost:3000 |
| Postgres  | localhost:5432        |

Migrations run automatically when khazina starts.

## Common tasks

```bash
mise tasks                      # list everything
mise run test                   # Go tests (starts a throwaway Postgres on :5433)
mise run test:e2e               # Playwright e2e, needs khazina/tests/e2e/.env
mise run gen                    # sqlc, templ, mockery, buf
mise run lint
mise run migrate:create <name>
```

## Deploying

See [`infra/README.md`](infra/README.md).

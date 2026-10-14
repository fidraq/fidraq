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

## Getting started

You need [mise](https://mise.jdx.dev) and a Docker runtime such as
[OrbStack](https://orbstack.dev) (only Postgres runs in Docker). mise installs
every other tool at the pinned version.

```bash
mise install      # Go, Bun, buf, sqlc, templ, ...
mise run setup    # generates your local secrets into mise.local.toml
mise run dev      # Postgres + khazina + diwan, with hot reload
```

| Service | URL                   |
| ------- | --------------------- |
| khazina | http://localhost:8080 |
| diwan   | http://localhost:5173 |

Config lives in two places:

- `mise.toml`: dev defaults (database URL, ports, ...), committed.
- `mise.local.toml`: your secrets, gitignored. Re-run `mise run setup` after
  pulling; it only adds variables you don't have yet.

Production reads the same variable names from its own environment.

## Common tasks

```bash
mise tasks                      # list everything
mise run test                   # Go tests (throwaway Postgres on :5433)
mise run test:e2e               # Playwright e2e, needs MPGS test creds in mise.local.toml
mise run gen                    # sqlc, templ, mockery, buf
mise run lint
mise run migrate:create <name>
```

## Deploying

Each push to `main` publishes Docker images to
`ghcr.io/rbconsult-bh/saftaja`. A Helm chart for self-hosting is coming.

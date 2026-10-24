# Fidraq (formerly Saftaja) | فِضْرَق

Self-hostable, open-source payments on top of MPGS (Mastercard Payment Gateway
Services), the gateway most Gulf banks hand to merchants. Fidraq gives you a hosted
checkout with 3-D Secure, payment links and a dashboard, so you don't have to
integrate MPGS by hand.

> **Status:** pre-release. Card payments with 3DS work end to end. The payments core is
> being rebuilt for v0.1; see [the design](docs/design/payments-core-v1.md). Apple Pay,
> the merchant API and webhooks come after.

## Why Fidraq

Said FID-raq. A blend of two Arabic words: fiḍḍa (فضة), silver, and waraq (ورق), paper.
Silver and paper: the two forms money has always taken.

## Repo layout

| Path      | What                                                        |
| --------- | ----------------------------------------------------------- |
| `khazina` | Go backend: payments, hosted checkout, dashboard API        |
| `diwan`   | Merchant dashboard (React + Vite)                           |
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
| khazina | <http://localhost:8080> |
| diwan   | <http://localhost:5173> |

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

Pushing a version tag (`v0.1.0`) publishes the khazina image to
`ghcr.io/fidraq/fidraq/khazina`, tagged `0.1.0`, `0.1` and `latest`.
Pull requests build the image without publishing it. A Helm chart for
self-hosting is coming.

## License

Copyright (C) 2025-2026 Yazeed AlKhalaf

Fidraq is free software: you can redistribute it and/or modify it under the
terms of the GNU Affero General Public License, version 3 only, as published by
the Free Software Foundation. See [LICENSE](LICENSE) for the full text.

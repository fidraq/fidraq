# e2e tests

Runs a real card payment against the MPGS test gateway. Khazina and Postgres are
started in Docker and exposed through a public tunnel so 3DS can call back.

Put your MPGS test merchant credentials in `mise.local.toml` at the repo root
(`mise run setup` creates it), then from the repo root:

```bash
mise run test:e2e
```

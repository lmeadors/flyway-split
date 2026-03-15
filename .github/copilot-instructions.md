# Copilot Instructions — bookstore

## Project purpose

This repository demonstrates how to use [Flyway](https://flywaydb.org/) to
split database migrations by **concern and ownership** rather than running
everything as a single superuser. It is intentionally a working demo, not a
framework — keep it simple and focused.

## Two-team model

| Team                | Owns                                            | Credentials needed      |
|---------------------|-------------------------------------------------|-------------------------|
| **Platform team**   | `db/admin/` migrations — schema, roles, grants  | Superuser (`postgres`)  |
| **Bookstore squad** | `db/bookstore/` migrations — tables, views, etc | App user (`app_user`)   |

The platform team provisions all credentials. `APP_USER_PASSWORD` is the
**handoff credential**: the platform team sets it; the bookstore squad reads
it to run their migrations. The bookstore squad never needs superuser access.

In production these would be **two separate repositories** (`platform-db` and
`bookstore-db`) to allow independent branching, tagging, and release cycles.
This repo combines them for demo convenience — do not interpret the single-repo
structure as a recommendation.

## Environments

| Name          | Type                  | Notes                                      |
|---------------|-----------------------|--------------------------------------------|
| `development` | Ephemeral / local     | Run via docker-compose on a dev machine    |
| `test`        | Ephemeral             | Throwaway CI job databases                 |
| `staging`     | Persistent / shared   | Long-lived; secrets in secrets manager     |
| `production`  | Persistent / shared   | Long-lived; secrets in secrets manager     |

## Configuration contract

All connection details **and** credentials are supplied via a `.env` file.
`docker-compose.yml` contains no hardcoded values — only `${VAR}` references.

| Variable                  | Description                        |
|---------------------------|------------------------------------|
| `DB_HOST`                 | Database hostname (`db` for local) |
| `DB_PORT`                 | Database port (typically `5432`)   |
| `DB_NAME`                 | Database name                      |
| `DB_ADMIN_PASSWORD`       | Database admin password            |
| `APP_USER_PASSWORD`       | Application user password          |
| `REPORTING_USER_PASSWORD` | Reporting user password            |

## Secret naming convention

```
/{env}/{app}/{secret-name}
```

Examples:
- `/development/bookstore/app-user-password`
- `/production/bookstore/postgres-password`

Supported backends in `scripts/fetch-secrets.sh`: `local`, `ssm`,
`secretsmanager`, `vault`.

## Guiding principle

> **Choose effective over right.**
>
> When forced to pick between doing something the theoretically correct way
> and doing something that actually works for the people using it, choose
> the approach that works. Pragmatic and useful beats pure and unusable.

## What to avoid

- Do not add new migration concerns without considering team ownership.
- Do not hardcode credentials, hostnames, or database names in
  `docker-compose.yml` — all runtime config goes through `.env`.
- Do not commit `.env` — it is git-ignored by design.
- Do not over-engineer: this is a demo. Resist adding abstractions,
  wrapper scripts, or tooling that isn't directly needed.

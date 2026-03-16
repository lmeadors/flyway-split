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

Supported backends in `scripts/fetch-secrets-{backend}.sh`: `local`, `ssm`,
`secretsmanager`, `vault`.

## Guiding principle

> **Choose effective over right.**
>
> When forced to pick between doing something the theoretically correct way
> and doing something that actually works for the people using it, choose
> the approach that works. Pragmatic and useful beats pure and unusable.

## Flyway migration conventions

**Versioned migrations (`V__`)** — tables, indexes, constraints, data patches.
- Append-only. Never edit a versioned file after it has been applied anywhere.
- Version numbers must be globally unique across all `FLYWAY_LOCATIONS` for a
  given runner. `tables/V4__foo.sql` and `views/V4__foo.sql` in the same runner will collide.
- Names use double underscores: `V1__create_authors_table.sql`.
- Each migration does one thing. Prefer many small migrations over one large one.

**Repeatable migrations (`R__`)** — views, functions, stored procedures.
- Named with a double underscore and no version: `R__book_listing.sql`.
- Re-applied automatically whenever the file's checksum changes.
- Always use `CREATE OR REPLACE` so re-application is idempotent.
- Edit the file in place to update the object — no new `V__` file needed.

**General rules**
- Every migration file must be idempotent where possible (`IF NOT EXISTS`,
  `CREATE OR REPLACE`, etc.).
- Admin migrations run as `postgres`; bookstore migrations run as `app_user`.
  Never cross those boundaries.
- History tables are schema-scoped: admin history lives in `public`, bookstore
  history lives in `bookstore`. Do not change `FLYWAY_DEFAULT_SCHEMA` without
  considering where the history table will land.

## SQL conventions

- Schema-qualify every object reference: `bookstore.authors`, not just `authors`.
  This prevents silent resolution against the wrong search path.
- Use `SERIAL` or `BIGSERIAL` for surrogate primary keys on new tables.
- Declare `NOT NULL` explicitly on every column that must have a value.
- Define foreign keys with `ON DELETE CASCADE` or `ON DELETE RESTRICT` — never
  leave referential action implicit.
- `TIMESTAMP` columns default to `NOW()` for `created_at`/`updated_at`.
- Index columns used in `WHERE`, `JOIN ON`, and `ORDER BY` clauses.
- Do not use `SELECT *` in views — list columns explicitly so changes to the
  underlying table don't silently change the view's output shape.

## What to avoid

- Do not add new migration concerns without considering team ownership.
- Do not hardcode credentials, hostnames, or database names in
  `docker-compose.yml` — all runtime config goes through `.env`.
- Do not commit `.env` — it is git-ignored by design.
- Do not over-engineer: this is a demo. Resist adding abstractions,
  wrapper scripts, or tooling that isn't directly needed.

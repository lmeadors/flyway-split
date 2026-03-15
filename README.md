# flyway-split

A demonstration of how to use [Flyway](https://flywaydb.org/) to manage two
separate database concerns:

- Database Administration (run by a DBA with superuser credentials)
  - schema creation
  - role management
  - permission grants
- Database Development (run by a
   developer with application-level credentials)
  - tables
  - views 
  - indices


## Why split migrations?

| Concern                 | Who owns it | Credentials needed      |
|-------------------------|-------------|-------------------------|
| Schema, roles, grants   | DBA         | Superuser (`postgres`)  |
| Tables, views, indexes  | Bookstore squad | App user (`app_user`)   |

Splitting migrations by concern provides several benefits:

- **Security** – developers never need superuser access.
- **Auditing** – administrative changes (roles, credentials) are tracked in a
  separate history table from schema changes.
- **Clear ownership** – DBAs review and merge admin migrations; the bookstore
  squad reviews and merges bookstore migrations.
- **Independent deployability** – either set of migrations can be deployed and
  rolled back without touching the other.
- **Independent versioning** – each concern can be branched, tagged, and
  released on its own schedule.


## In production: two repos

This demo collapses both concerns into one repository for convenience. In
practice, each team would own a separate repository:

Separate repos mean separate branching strategies, release tags, and PR
review gates — the platform team's release cycle does not block the bookstore
squad's, and vice versa. The `APP_USER_PASSWORD` handoff credential is the
only runtime coupling between them.


## Scaling the pattern: domains and bounded contexts

This two-repo model scales naturally when organized around **domains** and
**bounded contexts**.

### The hierarchy

| Level           | Repo            | Owner             | Contains                              |
|-----------------|-----------------|-------------------|---------------------------------------|
| Domain          | `platform-db`   | Platform/DBA team | Databases, roles, grants, extensions  |
| Bounded context | `<context>-db`  | Context squad     | All schemas within that context       |

A **domain** maps to a single database and a single `platform-db` repo. The
platform team creates the database, provisions all roles, and manages anything
that requires superuser access. One platform repo per domain keeps
administrative ownership clear and avoids coordination overhead.

A **bounded context** within that domain gets its own `<context>-db` repo and
its own schema (or set of schemas). Multiple services within the same bounded
context can share a single context repo, each owning a separate schema.

### Coupling flows in one direction only

```
platform-db  →  (provisions credentials)  →  <context>-db
```

The context squad knows their `APP_USER_PASSWORD` was set by the platform
team. They never need access to the platform repo. The platform team never
needs to touch the context repos.

### When to use a separate database (and a new platform repo)

Use **one database per domain**; use **one schema per bounded context or
service**. Add a second database — and therefore a second `platform-db` —
only when contexts are unrelated enough that sharing a failure domain,
extension set, or credential lifecycle would be a burden rather than a
simplification.

### Using this pattern in a scoped monorepo

If multiple services live in the same monorepo, the pattern still applies as
long as those services belong to the same bounded context. Each service gets
its own subdirectory under `db/` and its own schema. The admin migrations
directory (`db/admin/`) is the one shared resource — treat it with the same
PR review discipline as a shared library.

Cross-schema SQL joins are a warning sign: if two schemas frequently need to
query each other directly, they may belong in the same schema. If they should
stay separate, expose data via views or APIs rather than direct cross-schema
references.


## Project structure

```
db/
├── admin/                                    # DBA-managed migrations
│   └── sql/
│       ├── V1__create_schema.sql             # Create the bookstore schema
│       ├── V2__create_roles.sql              # Create app_user and reporting_user
│       └── V3__grant_permissions.sql         # Grant schema privileges to roles
└── bookstore/                                # Bookstore squad migrations
    └── sql/
        ├── tables/                           # Versioned DDL — append-only
        │   ├── V1__create_authors_table.sql  # authors table
        │   ├── V2__create_books_table.sql    # books table
        │   ├── V3__create_book_authors_table.sql # join table
        │   └── V4__create_indexes.sql        # performance indexes
        └── views/                            # Repeatable migrations — edit in place
            └── R__book_listing.sql           # book_listing view
```

Each migration set has its own Flyway configuration (passed via environment
variables in `docker-compose.yml`):

| Setting         | Admin                           | Bookstore                                              |
|-----------------|---------------------------------|--------------------------------------------------------|
| Connected user  | `postgres` (superuser)          | `app_user`                                             |
| Default schema  | `public`                        | `bookstore`                                            |
| History table   | `public.flyway_schema_history`  | `bookstore.flyway_schema_history`                      |
| SQL locations   | `db/admin/sql`                  | `db/bookstore/sql/tables`, `db/bookstore/sql/views`    |

Versioned migrations (`V__`) in `tables/` are append-only and run once.
Repeatable migrations (`R__`) in `views/` re-run whenever the file content changes,
making it easy to update a view by editing it in place rather than adding a new versioned file.


## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) 
- [Docker Compose](https://docs.docker.com/compose/install/)

> This demo uses PostgreSQL, but the pattern applies to any database
> [Flyway supports](https://documentation.red-gate.com/flyway/flyway-cli-and-api/supported-databases).
> Swap the `db` service image and JDBC URL in `docker-compose.yml` for your target database.


## Running the demo

> **Order matters.** Admin migrations must run before bookstore migrations
> because bookstore migrations connect as `app_user`, which is created by the
> admin migrations. Running bookstore migrations first will fail.

### 1 – Start the database

```bash
docker-compose up -d db
```

### 2 – Run admin migrations (DBA step)

```bash
docker-compose run --rm migrate-admin
```

Flyway connects as `postgres` and applies:

| Migration                   | What it does                                  |
|-----------------------------|-----------------------------------------------|
| `V1__create_schema.sql`     | Creates the `bookstore` schema                |
| `V2__create_roles.sql`      | Creates `app_user` and `reporting_user` roles |
| `V3__grant_permissions.sql` | Grants appropriate privileges on the schema   |

The migration history is stored in `public.flyway_schema_history`.

### 3 – Run bookstore migrations (bookstore squad step)

```bash
docker-compose run --rm migrate-bookstore
```

Flyway connects as `app_user` (created in step 2) and applies migrations from
two locations — `tables/` first, then `views/`:

| Migration                               | Type        | What it does                              |
|-----------------------------------------|-------------|-------------------------------------------|
| `tables/V1__create_authors_table.sql`   | Versioned   | `bookstore.authors` table                 |
| `tables/V2__create_books_table.sql`     | Versioned   | `bookstore.books` table                   |
| `tables/V3__create_book_authors_table.sql` | Versioned | `bookstore.book_authors` join table      |
| `tables/V4__create_indexes.sql`         | Versioned   | Indexes on title, ISBN, author last name  |
| `views/R__book_listing.sql`             | Repeatable  | `bookstore.book_listing` view             |

The migration history is stored in `bookstore.flyway_schema_history`.


## Verifying the result

Open a psql shell:

```bash
docker-compose exec db psql -U postgres bookstore_db
```

Then inspect the objects that were created:

```sql
-- Admin objects
\dn                                      -- list schemas
\du                                      -- list roles
SELECT * FROM public.flyway_schema_history;

-- Bookstore objects
\dt bookstore.*                          -- list tables
\dv bookstore.*                          -- list views
\di bookstore.*                          -- list indexes
SELECT * FROM bookstore.flyway_schema_history;
```


## Resetting the demo

```bash
docker-compose down -v   # removes containers AND the postgres volume
docker-compose up -d db  # restart the database
```

---

## Credentials & Configuration

All connection details and credentials are supplied via a `.env` file that
docker-compose reads automatically. The file is git-ignored. A committed
`.env.example` documents every required variable.

### Two-team ownership

| Variable                        | Owner         | Who needs it at runtime |
|---------------------------------|---------------|-------------------------|
| `DB_HOST`, `DB_PORT`, `DB_NAME` | Platform team | Both teams              |
| `DB_ADMIN_PASSWORD`             | Platform team | Admin migrations only   |
| `REPORTING_USER_PASSWORD`       | Platform team | Admin migrations only   |
| `APP_USER_PASSWORD`             | Platform team | Handoff credential      |

The bookstore squad needs the `APP_USER_PASSWORD` value to run their migrations.

The IAM policy (or Vault policy) is the enforcement boundary: 

- The bookstore squad's CI/CD role has read access only to their own secrets path.

### Secret naming convention

All secrets follow `/{env}/{app}/{secret-name}`:

| Environment   | Type        | Example path                                |
|---------------|-------------|---------------------------------------------|
| `development` | ephemeral   | `/development/bookstore/app-user-password`  |
| `test`        | ephemeral   | `/test/bookstore/app-user-password`         |
| `staging`     | persistent  | `/staging/bookstore/app-user-password`      |
| `production`  | persistent  | `/production/bookstore/app-user-password`   |

- The `development` and `test` environments are local or short-lived.
  — The developers run them on their own machines or in throwaway CI jobs. 
- The `staging` and `production` are shared and persistent. 
  - Their secrets live in the secrets manager and are never distributed as plain text.

### Local development workflow

```bash
cp .env.example .env
# Edit .env — set DB_HOST=db, DB_PORT=5432, DB_NAME=bookstore_db, and passwords
docker-compose up -d db
docker-compose run --rm migrate-admin
docker-compose run --rm migrate-bookstore
```

### CI/CD workflow (staging / production)

The `scripts/fetch-secrets-{backend}.sh` scripts populate `.env` from your
secrets backend before running Flyway. The docker-compose interface is unchanged.

```bash
# Fetch secrets, then migrate
ENV=staging APP=bookstore ./scripts/fetch-secrets-ssm.sh
docker-compose run --rm migrate-admin
docker-compose run --rm migrate-bookstore
```

Available scripts:

| Script                                    | Backend                     |
|-------------------------------------------|-----------------------------|
| `scripts/fetch-secrets-local.sh`          | Local `.env` (verify only)  |
| `scripts/fetch-secrets-ssm.sh`            | AWS SSM Parameter Store     |
| `scripts/fetch-secrets-secretsmanager.sh` | AWS Secrets Manager         |
| `scripts/fetch-secrets-vault.sh`          | HashiCorp Vault             |

Example GitHub Actions step:

```yaml
- name: Fetch secrets
  run: ENV=staging APP=bookstore ./scripts/fetch-secrets-ssm.sh
  env:
    AWS_REGION: us-east-1
    # AWS credentials supplied via OIDC role assumption

- name: Run migrations
  run: |
    docker-compose run --rm migrate-admin
    docker-compose run --rm migrate-bookstore
```


# flyway-split

A demonstration of how to use [Flyway](https://flywaydb.org/) to manage two
separate database concerns:

1. **Database Administration** – schema creation, role management, permission
   grants (run by a DBA with superuser credentials).
2. **Database Development** – table, view, and index creation (run by a
   developer with application-level credentials).

---

## Why split migrations?

| Concern | Who owns it | Credentials needed |
|---------|-------------|-------------------|
| Schema, roles, grants | DBA | Superuser (`postgres`) |
| Tables, views, indexes | Developer | App user (`app_user`) |

Splitting migrations by concern provides several benefits:

- **Security** – developers never need superuser access.
- **Auditing** – administrative changes (roles, credentials) are tracked in a
  separate history table from schema changes.
- **Clear ownership** – DBAs review and merge admin migrations; developers
  review and merge dev migrations.
- **Independent deployability** – either set of migrations can be deployed and
  rolled back without touching the other.

---

## Project structure

```
db/
├── admin/                          # DBA-managed migrations
│   └── sql/
│       ├── V1__create_schema.sql           # Create the bookstore schema
│       ├── V2__create_roles.sql            # Create app_user and reporting_user
│       └── V3__grant_permissions.sql       # Grant schema privileges to roles
└── dev/                            # Developer-managed migrations
    └── sql/
        ├── V1__create_authors_table.sql    # authors table
        ├── V2__create_books_table.sql      # books table
        ├── V3__create_book_authors_table.sql # join table
        ├── V4__create_views.sql            # book_listing view
        └── V5__create_indexes.sql          # performance indexes
```

Each migration set has its own Flyway configuration (passed via environment
variables in `docker-compose.yml`):

| Setting | Admin | Dev |
|---------|-------|-----|
| Connected user | `postgres` (superuser) | `app_user` |
| Default schema | `public` | `bookstore` |
| History table | `public.flyway_admin_history` | `bookstore.flyway_dev_history` |
| SQL location | `db/admin/sql` | `db/dev/sql` |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and
  [Docker Compose](https://docs.docker.com/compose/install/) – that's it.

---

## Running the demo

### 1 – Start the database

```bash
docker-compose up -d db
# or
make start
```

### 2 – Run admin migrations (DBA step)

```bash
docker-compose run --rm migrate-admin
# or
make migrate-admin
```

Flyway connects as `postgres` and applies:

| Migration | What it does |
|-----------|-------------|
| `V1__create_schema.sql` | Creates the `bookstore` schema |
| `V2__create_roles.sql` | Creates `app_user` and `reporting_user` roles |
| `V3__grant_permissions.sql` | Grants appropriate privileges on the schema |

The migration history is stored in `public.flyway_admin_history`.

### 3 – Run dev migrations (developer step)

```bash
docker-compose run --rm migrate-dev
# or
make migrate-dev
```

Flyway connects as `app_user` (created in step 2) and applies:

| Migration | What it does |
|-----------|-------------|
| `V1__create_authors_table.sql` | `bookstore.authors` table |
| `V2__create_books_table.sql` | `bookstore.books` table |
| `V3__create_book_authors_table.sql` | `bookstore.book_authors` join table |
| `V4__create_views.sql` | `bookstore.book_listing` view |
| `V5__create_indexes.sql` | Indexes on title, ISBN, author last name |

The migration history is stored in `bookstore.flyway_dev_history`.

### Run both in one command

```bash
docker-compose up migrate-dev   # admin runs first via depends_on
# or
make migrate
```

---

## Verifying the result

Open a psql shell:

```bash
make psql
# or
docker-compose exec db psql -U postgres bookstore_db
```

Then inspect the objects that were created:

```sql
-- Admin objects
\dn                                      -- list schemas
\du                                      -- list roles
SELECT * FROM public.flyway_admin_history;

-- Dev objects
\dt bookstore.*                          -- list tables
\dv bookstore.*                          -- list views
\di bookstore.*                          -- list indexes
SELECT * FROM bookstore.flyway_dev_history;
```

---

## Resetting the demo

```bash
docker-compose down -v   # removes containers AND the postgres volume
# or
make reset               # same, then restarts the db
```

---

## Make targets

```
make help          Show all available targets
make start         Start the database container
make stop          Stop all containers
make migrate       Run admin then dev migrations
make migrate-admin Run only the admin migrations
make migrate-dev   Run only the dev migrations
make reset         Destroy everything and restart the database
make logs          Tail container logs
make psql          Open a psql shell as postgres
```
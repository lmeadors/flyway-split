# platform-db

Flyway migrations owned by the **platform team**. These run as a database
superuser and provision everything the application teams need to operate.

---

## What this repo provisions

### Schema

| Object            | Purpose                              |
|-------------------|--------------------------------------|
| `bookstore`       | Application schema owned by `app_user` |

### Roles

| Role               | Type      | Purpose                                                  |
|--------------------|-----------|----------------------------------------------------------|
| `app_user`         | Read/write | Runtime application account; also used by the bookstore squad to run their own migrations |
| `reporting_user`   | Read-only  | Used by BI tools and data pipelines; can never mutate data |

`app_user` and `reporting_user` passwords are injected at migration time via
Flyway placeholders — they are never hardcoded in SQL or source control.

### Permissions granted to `app_user`

- `USAGE` and `CREATE` on the `bookstore` schema
- `SELECT`, `INSERT`, `UPDATE`, `DELETE` on all current and future tables
- `USAGE` on all current and future sequences

### Permissions granted to `reporting_user`

- `USAGE` on the `bookstore` schema
- `SELECT` on all current and future tables

---

## Credential handoff

`APP_USER_PASSWORD` is the **handoff credential**: the platform team sets it
in the secrets manager; the bookstore squad reads it to connect and run their
migrations. It is the only secret the bookstore squad needs.

---

## Running migrations

See the top-level `README.md` for setup. Admin migrations must run before
bookstore migrations.

```bash
docker-compose run --rm migrate-admin
```

Migration history is stored in `public.flyway_schema_history`.

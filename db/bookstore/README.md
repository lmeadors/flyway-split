# bookstore-db

Flyway migrations owned by the **bookstore squad**. These run as `app_user`
and manage all schema objects within the `bookstore` schema.

The `bookstore` schema and `app_user` role are provisioned by the platform
team (`platform-db`). The only credential this repo needs is `APP_USER_PASSWORD`.

---

## Schema objects

### Tables

| Table                    | Purpose                                      |
|--------------------------|----------------------------------------------|
| `bookstore.authors`      | Author records (name, bio)                   |
| `bookstore.books`        | Book records (title, ISBN, price, description) |
| `bookstore.book_authors` | Many-to-many join between books and authors  |

### Views

| View                      | Purpose                                                  |
|---------------------------|----------------------------------------------------------|
| `bookstore.book_listing`  | Joins books with authors into a single denormalised row; used by reporting tools |

### Indexes

| Index                       | Column                  | Purpose                      |
|-----------------------------|-------------------------|------------------------------|
| `idx_books_title`           | `books.title`           | Title search                 |
| `idx_books_isbn`            | `books.isbn`            | ISBN lookup                  |
| `idx_authors_last_name`     | `authors.last_name`     | Author name search           |

---

## Running migrations

See the top-level `README.md` for setup. Admin migrations (platform team)
must run before these.

```bash
docker-compose run --rm migrate-bookstore
```

Migration history is stored in `bookstore.flyway_schema_history`.

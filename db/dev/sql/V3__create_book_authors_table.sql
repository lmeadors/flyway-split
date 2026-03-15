-- =============================================================================
-- Dev migration: Create the book_authors join table
--
-- Owned by: Developer
-- Run as:   app_user
-- =============================================================================

CREATE TABLE bookstore.book_authors (
    book_id     INTEGER NOT NULL REFERENCES bookstore.books(id)   ON DELETE CASCADE,
    author_id   INTEGER NOT NULL REFERENCES bookstore.authors(id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, author_id)
);

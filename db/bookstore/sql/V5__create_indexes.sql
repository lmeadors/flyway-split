-- =============================================================================
-- Bookstore migration: Create performance indexes
--
-- Owned by: Bookstore squad
-- Run as:   app_user
-- =============================================================================

CREATE INDEX idx_books_title      ON bookstore.books(title);
CREATE INDEX idx_books_isbn       ON bookstore.books(isbn);
CREATE INDEX idx_authors_last_name ON bookstore.authors(last_name);

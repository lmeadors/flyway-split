-- =============================================================================
-- Bookstore migration: Create the books table
--
-- Owned by: Bookstore squad
-- Run as:   app_user
-- =============================================================================

CREATE TABLE bookstore.books (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(255) NOT NULL,
    isbn            VARCHAR(20)  UNIQUE,
    description     TEXT,
    published_date  DATE,
    price           NUMERIC(10, 2),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

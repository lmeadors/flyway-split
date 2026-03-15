-- =============================================================================
-- Dev migration: Create the authors table
--
-- Owned by: Developer
-- Run as:   app_user
-- =============================================================================

CREATE TABLE bookstore.authors (
    id          SERIAL PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    bio         TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

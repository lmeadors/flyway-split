-- =============================================================================
-- Admin migration: Grant schema permissions to roles
--
-- Owned by: Database Administrator
-- Run as:   postgres (superuser)
--
-- app_user       - full read/write access to the bookstore schema, plus the
--                  ability to create objects (needed to run bookstore migrations
--                  and to store the Flyway history table).
-- reporting_user - read-only access to the bookstore schema.
-- =============================================================================

-- Allow both roles to see objects in the schema
GRANT USAGE ON SCHEMA bookstore TO app_user;
GRANT USAGE ON SCHEMA bookstore TO reporting_user;

-- Allow app_user to create objects (tables, views, indexes, history table)
GRANT CREATE ON SCHEMA bookstore TO app_user;

-- Grant data privileges on all existing tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA bookstore TO app_user;
GRANT SELECT ON ALL TABLES IN SCHEMA bookstore TO reporting_user;

-- Apply the same privileges automatically to any tables created in the future
ALTER DEFAULT PRIVILEGES IN SCHEMA bookstore
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA bookstore
    GRANT SELECT ON TABLES TO reporting_user;

-- Allow app_user to use sequences (needed for SERIAL / GENERATED columns)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA bookstore TO app_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA bookstore
    GRANT USAGE ON SEQUENCES TO app_user;

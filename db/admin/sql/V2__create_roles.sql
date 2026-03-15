-- =============================================================================
-- Admin migration: Create application roles
--
-- Owned by: Database Administrator
-- Run as:   postgres (superuser)
--
-- app_user        - The account used by the application at runtime and by
--                   developers running dev migrations.
-- reporting_user  - A read-only account used by reporting/analytics tools.
--
-- Passwords are injected via Flyway placeholders so they are never hardcoded
-- in source control.  Set them in docker-compose.yml (or your CI/CD secrets):
--   FLYWAY_PLACEHOLDERS_APP_USER_PASSWORD
--   FLYWAY_PLACEHOLDERS_REPORTING_USER_PASSWORD
-- =============================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user LOGIN PASSWORD '${app_user_password}';
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'reporting_user') THEN
        CREATE ROLE reporting_user LOGIN PASSWORD '${reporting_user_password}';
    END IF;
END
$$;

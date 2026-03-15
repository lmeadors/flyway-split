#!/usr/bin/env bash
# =============================================================================
# fetch-secrets-vault.sh — Populate .env from HashiCorp Vault
#
# All values are stored as fields in a single KV secret:
#   secret/{ENV}/{APP}/database
#   e.g. secret/staging/bookstore/database
#
# Requirements:
#   - vault CLI installed and on PATH
#   - VAULT_ADDR and VAULT_TOKEN set (or another supported auth method)
#
# Usage:
#   ENV=staging APP=bookstore ./scripts/fetch-secrets-vault.sh
#
# Environment variables:
#   ENV  development | test | staging | production  (default: development)
#   APP  application name used in secret paths  (required — no default)
# =============================================================================

set -euo pipefail

ENV="${ENV:-development}"
APP="${APP:?ERROR: APP must be set (e.g. APP=bookstore)}"
PREFIX="/${ENV}/${APP}"
ENV_FILE="$(dirname "$0")/../.env"

echo "Fetching from HashiCorp Vault (path: secret${PREFIX}/database)"

get_vault() {
  vault kv get -field="$1" "secret${PREFIX}/database"
}

cat > "$ENV_FILE" <<EOF
DB_HOST=$(get_vault db-host)
DB_PORT=$(get_vault db-port)
DB_NAME=$(get_vault db-name)
DB_ADMIN_PASSWORD=$(get_vault db-admin-password)
APP_USER_PASSWORD=$(get_vault app-user-password)
REPORTING_USER_PASSWORD=$(get_vault reporting-user-password)
EOF

echo ".env written from Vault (env: ${ENV}, app: ${APP})"

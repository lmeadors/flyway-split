#!/usr/bin/env bash
# =============================================================================
# fetch-secrets-secretsmanager.sh — Populate .env from AWS Secrets Manager
#
# All values are stored as keys in a single JSON secret:
#   /{ENV}/{APP}/database
#   e.g. /staging/bookstore/database
#
# Requirements:
#   - aws CLI and jq installed and on PATH
#   - AWS credentials with secretsmanager:GetSecretValue on /${ENV}/${APP}/*
#
# Usage:
#   ENV=staging APP=bookstore ./scripts/fetch-secrets-secretsmanager.sh
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

echo "Fetching from AWS Secrets Manager (secret: ${PREFIX}/database)"

SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${PREFIX}/database" \
  --query SecretString --output text)

get_key() { echo "$SECRET" | jq -r ".[\"$1\"]"; }

cat > "$ENV_FILE" <<EOF
DB_HOST=$(get_key db-host)
DB_PORT=$(get_key db-port)
DB_NAME=$(get_key db-name)
DB_ADMIN_PASSWORD=$(get_key db-admin-password)
APP_USER_PASSWORD=$(get_key app-user-password)
REPORTING_USER_PASSWORD=$(get_key reporting-user-password)
EOF

echo ".env written from Secrets Manager (env: ${ENV}, app: ${APP})"

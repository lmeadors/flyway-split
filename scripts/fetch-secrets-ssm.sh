#!/usr/bin/env bash
# =============================================================================
# fetch-secrets-ssm.sh — Populate .env from AWS SSM Parameter Store
#
# Connection details are stored as plain String parameters.
# Passwords are stored as SecureString parameters.
#
# Secret naming convention: /{ENV}/{APP}/{secret-name}
#   e.g. /staging/bookstore/app-user-password
#
# Requirements:
#   - aws CLI installed and on PATH
#   - AWS credentials with ssm:GetParameter on /${ENV}/${APP}/*
#
# Usage:
#   ENV=staging APP=bookstore ./scripts/fetch-secrets-ssm.sh
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

echo "Fetching from AWS SSM Parameter Store (prefix: ${PREFIX})"

get_ssm() {
  aws ssm get-parameter --name "${PREFIX}/$1" --with-decryption \
    --query Parameter.Value --output text
}

cat > "$ENV_FILE" <<EOF
DB_HOST=$(get_ssm db-host)
DB_PORT=$(get_ssm db-port)
DB_NAME=$(get_ssm db-name)
DB_ADMIN_PASSWORD=$(get_ssm db-admin-password)
APP_USER_PASSWORD=$(get_ssm app-user-password)
REPORTING_USER_PASSWORD=$(get_ssm reporting-user-password)
EOF

echo ".env written from SSM (env: ${ENV}, app: ${APP})"

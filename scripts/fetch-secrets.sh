#!/usr/bin/env bash
# =============================================================================
# fetch-secrets.sh — Populate .env from a secrets backend
#
# Usage:
#   SECRETS_BACKEND=local       APP=bookstore ./scripts/fetch-secrets.sh   # no-op, use .env as-is
#   SECRETS_BACKEND=ssm         ENV=staging  APP=bookstore ./scripts/fetch-secrets.sh
#   SECRETS_BACKEND=secretsmanager ENV=production APP=bookstore ./scripts/fetch-secrets.sh
#   SECRETS_BACKEND=vault       ENV=staging  APP=bookstore ./scripts/fetch-secrets.sh
#
# Environment variables:
#   SECRETS_BACKEND  local | ssm | secretsmanager | vault  (default: local)
#   ENV              development | test | staging | production  (default: development)
#   APP              application name used in secret paths  (required — no default)
#
# Secret naming convention:  /{ENV}/{APP}/{secret-name}
#
# For local docker-compose, set DB_HOST=db (.env.example explains why).
# For deployed environments, DB_HOST is the real database hostname.
# =============================================================================

set -euo pipefail

SECRETS_BACKEND="${SECRETS_BACKEND:-local}"
ENV="${ENV:-development}"
APP="${APP:?ERROR: APP must be set (e.g. APP=bookstore)}"
PREFIX="/${ENV}/${APP}"
ENV_FILE="$(dirname "$0")/../.env"

# -----------------------------------------------------------------------------
case "$SECRETS_BACKEND" in

# -- local --------------------------------------------------------------------
# No-op: the caller manages .env by hand (e.g. copied from .env.example).
local)
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env not found. Copy .env.example to .env and fill in values." >&2
    exit 1
  fi
  echo "SECRETS_BACKEND=local: using existing .env"
  exit 0
  ;;

# -- AWS SSM Parameter Store --------------------------------------------------
# Plain parameters for connection details; SecureString for passwords.
# Requires: aws CLI, credentials with ssm:GetParameter on ${PREFIX}/*
ssm)
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
  ;;

# -- AWS Secrets Manager ------------------------------------------------------
# All values stored as keys in a single JSON secret: ${PREFIX}/database
# Requires: aws CLI + jq, credentials with secretsmanager:GetSecretValue
secretsmanager)
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
  ;;

# -- HashiCorp Vault ----------------------------------------------------------
# All values stored as fields in a single KV secret: secret${PREFIX}/database
# Requires: vault CLI, VAULT_ADDR + VAULT_TOKEN (or other auth method) set
vault)
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
  ;;

*)
  echo "ERROR: Unknown SECRETS_BACKEND '${SECRETS_BACKEND}'. Use: local, ssm, secretsmanager, vault" >&2
  exit 1
  ;;
esac

echo ".env written from ${SECRETS_BACKEND} (env: ${ENV}, app: ${APP})"

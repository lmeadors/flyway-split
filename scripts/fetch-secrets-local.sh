#!/usr/bin/env bash
# =============================================================================
# fetch-secrets-local.sh — Verify .env exists for local development
#
# No-op: the caller manages .env by hand (copied from .env.example).
# Fails fast if .env is missing so docker-compose doesn't silently use
# empty variable values.
#
# Usage:
#   ./scripts/fetch-secrets-local.sh
# =============================================================================

set -euo pipefail

ENV_FILE="$(dirname "$0")/../.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env not found. Copy .env.example to .env and fill in values." >&2
  exit 1
fi

echo "fetch-secrets-local: using existing .env"

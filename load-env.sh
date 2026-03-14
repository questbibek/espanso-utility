#!/usr/bin/env bash
# load-env.sh — Load .env file into current shell session
# Usage: source ~/espanso-utility/load-env.sh

ENV_FILE="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] .env file not found at: $ENV_FILE"
  echo "  Copy .env.example → .env and fill in your API keys."
  return 1
fi

set -o allexport
# shellcheck source=/dev/null
source "$ENV_FILE"
set +o allexport

echo "[OK] Environment loaded from $ENV_FILE"
echo "     Tip: add 'source ~/espanso-utility/load-env.sh' to your ~/.bashrc or ~/.zshrc"
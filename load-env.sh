#!/usr/bin/env bash
# =============================================
# load-env.sh
# Loads API keys from .env into shell environment
# Source this file (don't run it directly):
#   source ~/espanso-utility/load-env.sh
# Add to ~/.bashrc or ~/.zshrc to auto-load on every terminal
# =============================================

ENV_FILE="${1:-$HOME/espanso-utility/.env}"

echo ""
echo "========================================"
echo "  Loading .env into Environment"
echo "========================================"
echo ""

# ---- Check .env file ----
if [ ! -f "$ENV_FILE" ]; then
  echo "  .env not found at: $ENV_FILE"
  echo ""
  echo "  Create it with:"
  echo "    cp ~/espanso-utility/.env.example ~/espanso-utility/.env"
  echo "    code ~/espanso-utility/.env"
  return 1 2>/dev/null || exit 1
fi

# ---- Parse and export variables ----
loaded=0

while IFS= read -r line || [ -n "$line" ]; do
  # Trim whitespace
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  # Skip empty lines and comments
  [[ -z "$line" || "$line" == \#* ]] && continue

  # Split on first = only
  key="${line%%=*}"
  value="${line#*=}"

  # Skip if no key
  [ -z "$key" ] && continue

  # Skip placeholder values
  if [[ "$value" == your_* || -z "$value" ]]; then
    echo "  SKIPPED: $key (not configured)"
    continue
  fi

  # Export for current session
  export "$key=$value"

  # Persist permanently by writing to ~/.bashrc and ~/.zshrc
  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
      # Remove old entry if exists (sed -i differs between Mac and Linux)
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i "" "/^export $key=/d" "$rc_file"
      else
        sed -i "/^export $key=/d" "$rc_file"
      fi
      echo "export $key=$value" >> "$rc_file"
    fi
  done

  # Display masked value
  masked="${value:0:8}..."
  echo "  SET: $key = $masked"
  ((loaded++))

done < "$ENV_FILE"

echo ""
echo "========================================"
echo "  Loaded $loaded environment variable(s)"
echo "========================================"
echo ""
echo "  Variables are set permanently."
echo "  They persist across reboots and terminal sessions."
echo ""
echo "  IMPORTANT: Restart Espanso to pick up the new variables:"
echo "    espanso restart"
echo ""
echo "  Test it:"
echo "    echo \$OPENAI_API_KEY"
echo ""
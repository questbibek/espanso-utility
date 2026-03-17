#!/usr/bin/env bash
# cloudinary-clipboard.sh — Upload image from clipboard to Cloudinary
# Trigger: :clipss

source "$HOME/espanso-utility/shared.sh"

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
TEMP_FILE="/tmp/clipboard_${TIMESTAMP}.png"

# ── Save clipboard image to temp file ────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac — pngpaste saves clipboard image to file
  if ! command -v pngpaste &>/dev/null; then
    printf 'ERROR: pngpaste not installed. Run: brew install pngpaste'
    exit 1
  fi
  pngpaste "$TEMP_FILE" 2>/dev/null
else
  # Linux — xclip can save clipboard image
  if command -v xclip &>/dev/null; then
    xclip -selection clipboard -t image/png -o > "$TEMP_FILE" 2>/dev/null
  elif command -v wl-paste &>/dev/null; then
    wl-paste --type image/png > "$TEMP_FILE" 2>/dev/null
  else
    printf 'ERROR: No clipboard tool found'
    exit 1
  fi
fi

if [ ! -s "$TEMP_FILE" ]; then
  rm -f "$TEMP_FILE"
  printf 'No image in clipboard'
  exit 1
fi

# ── Upload to Cloudinary ──────────────────────────────────────────────────────
response=$(curl -s -X POST \
  -F "file=@$TEMP_FILE" \
  -F "upload_preset=$CLOUDINARY_UPLOAD_PRESET" \
  "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload")

rm -f "$TEMP_FILE"

url=$(echo "$response" | jq -r '.secure_url // empty')

if [ -n "$url" ]; then
  printf '%s' "$url"
else
  printf 'Error: %s' "$(echo "$response" | jq -r '.error.message // "Upload failed"')"
fi

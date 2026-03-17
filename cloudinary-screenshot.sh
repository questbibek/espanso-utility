#!/usr/bin/env bash
# cloudinary-screenshot.sh — Screenshot active monitor, upload to Cloudinary
# Trigger: :fullss

source "$HOME/espanso-utility/shared.sh"

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
TEMP_FILE="/tmp/screenshot_${TIMESTAMP}.png"

# ── Take screenshot ───────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac — screencapture active screen
  screencapture -x "$TEMP_FILE"
else
  # Linux — use scrot or gnome-screenshot
  if command -v scrot &>/dev/null; then
    scrot "$TEMP_FILE"
  elif command -v gnome-screenshot &>/dev/null; then
    gnome-screenshot -f "$TEMP_FILE"
  elif command -v import &>/dev/null; then
    import -window root "$TEMP_FILE"
  else
    printf 'ERROR: No screenshot tool found. Install scrot: sudo apt install scrot'
    exit 1
  fi
fi

if [ ! -f "$TEMP_FILE" ]; then
  printf 'ERROR: Screenshot failed'
  exit 1
fi

# ── Upload to Cloudinary ──────────────────────────────────────────────────────
response=$(curl -s -X POST \
  -F "file=@$TEMP_FILE" \
  -F "upload_preset=$CLOUDINARY_UPLOAD_PRESET" \
  "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload")

url=$(echo "$response" | jq -r '.secure_url // empty')

rm -f "$TEMP_FILE"

if [ -n "$url" ]; then
  printf '%s' "$url"
else
  printf 'Error: %s' "$(echo "$response" | jq -r '.error.message // "Upload failed"')"
fi

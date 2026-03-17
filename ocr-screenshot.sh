#!/usr/bin/env bash
# ocr-screenshot.sh — Extract text from clipboard image using OCR.space API
# Trigger: :ocr

source "$HOME/espanso-utility/shared.sh"

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
TEMP_FILE="/tmp/ocr_${TIMESTAMP}.png"

# ── Save clipboard image to temp file ────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! command -v pngpaste &>/dev/null; then
    printf 'ERROR: pngpaste not installed. Run: brew install pngpaste'
    exit 1
  fi
  pngpaste "$TEMP_FILE" 2>/dev/null
else
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
  printf 'ERROR: No image in clipboard. Take a screenshot first.'
  exit 1
fi

# ── Convert to base64 ─────────────────────────────────────────────────────────
base64_image=$(base64 < "$TEMP_FILE" | tr -d '\n')
base64_string="data:image/png;base64,${base64_image}"
rm -f "$TEMP_FILE"

# ── Call OCR.space API ────────────────────────────────────────────────────────
response=$(curl -s -X POST "https://api.ocr.space/parse/image" \
  -H "apikey: $OCR_SPACE_API_KEY" \
  -F "base64Image=$base64_string" \
  -F "language=eng" \
  -F "isOverlayRequired=false" \
  -F "detectOrientation=true" \
  -F "scale=true" \
  -F "OCREngine=2")

exit_code=$(echo "$response" | jq -r '.OCRExitCode // 0')
text=$(echo "$response" | jq -r '.ParsedResults[0].ParsedText // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ "$exit_code" == "1" ] || [ "$exit_code" == "2" ]; then
  if [ -n "$text" ]; then
    printf '%s' "$text"
  else
    printf 'ERROR: OCR returned empty result'
  fi
else
  error=$(echo "$response" | jq -r '.ErrorMessage[0] // "OCR failed"')
  printf 'ERROR: %s' "$error"
fi

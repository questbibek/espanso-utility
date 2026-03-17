#!/usr/bin/env bash
# cloudinary-upload.sh — Upload file(s) from clipboard to Cloudinary
# Trigger: :cloudinaryupload

source "$HOME/espanso-utility/shared.sh"

# ── Get file paths from clipboard ─────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  file_list=$(osascript -e 'tell application "Finder" to set sel to selection' \
    -e 'set output to ""' \
    -e 'repeat with f in sel' \
    -e 'set output to output & POSIX path of (f as alias) & linefeed' \
    -e 'end repeat' \
    -e 'return output' 2>/dev/null)
  if [ -z "$file_list" ]; then
    file_list=$(_clip_read)
  fi
else
  file_list=$(_clip_read)
fi

if [ -z "$file_list" ]; then
  printf 'No file in clipboard'
  exit 1
fi

# ── Determine resource type by extension ──────────────────────────────────────
get_resource_type() {
  local ext="${1##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  case "$ext" in
    mp4|mov|avi|mkv|webm) echo "video" ;;
    pdf|zip|txt|json|csv|docx|xlsx|html|htm|xml|pptx|doc|xls|ts|js|py|sh|ps1|sql|md|yaml|yml) echo "raw" ;;
    *) echo "image" ;;
  esac
}

# ── Upload each file ──────────────────────────────────────────────────────────
links=()

while IFS= read -r file_path; do
  file_path=$(echo "$file_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$file_path" ] && continue

  if [ ! -f "$file_path" ]; then
    links+=("Not found: $file_path")
    continue
  fi

  resource_type=$(get_resource_type "$file_path")
  upload_url="https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/$resource_type/upload"

  response=$(curl -s -X POST \
    -F "file=@$file_path" \
    -F "upload_preset=$CLOUDINARY_UPLOAD_PRESET" \
    "$upload_url")

  url=$(echo "$response" | jq -r '.secure_url // empty')
  error=$(echo "$response" | jq -r '.error.message // empty')

  if [ -n "$url" ]; then
    links+=("$url")
  elif [ -n "$error" ]; then
    links+=("Error ($(basename "$file_path")): $error")
  else
    links+=("Failed: $(basename "$file_path")")
  fi

done <<< "$file_list"

output=$(printf '%s\n' "${links[@]}")
printf '%s' "$output"

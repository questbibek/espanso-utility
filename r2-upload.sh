#!/usr/bin/env bash
# r2-upload.sh — Upload file(s) from clipboard to Cloudflare R2
# Trigger: :r2upload

source "$HOME/espanso-utility/shared.sh"

ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

get_content_type() {
  local ext="${1##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  case "$ext" in
    png)  echo "image/png" ;;
    jpg|jpeg) echo "image/jpeg" ;;
    gif)  echo "image/gif" ;;
    webp) echo "image/webp" ;;
    pdf)  echo "application/pdf" ;;
    zip)  echo "application/zip" ;;
    txt)  echo "text/plain" ;;
    json) echo "application/json" ;;
    csv)  echo "text/csv" ;;
    mp4)  echo "video/mp4" ;;
    html|htm) echo "text/html" ;;
    *)    echo "application/octet-stream" ;;
  esac
}

sanitize_filename() {
  local name="$1"
  local ext="${name##*.}"
  local base="${name%.*}"
  local clean
  clean=$(echo "$base" | sed 's/[^a-zA-Z0-9._-]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//')
  echo "${clean}.${ext}"
}

# ── Get file paths from clipboard ─────────────────────────────────────────────
file_list=$(_clip_read)
if [ -z "$file_list" ]; then
  printf 'No file in clipboard'
  exit 1
fi

links=()

while IFS= read -r file_path; do
  file_path=$(echo "$file_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$file_path" ] && continue

  if [ ! -f "$file_path" ]; then
    links+=("Not found: $file_path")
    continue
  fi

  original_name=$(basename "$file_path")
  file_name=$(sanitize_filename "$original_name")
  content_type=$(get_content_type "$file_name")

  response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    "${ENDPOINT}/${R2_BUCKET_NAME}/${file_name}" \
    --aws-sigv4 "aws:amz:auto:s3" \
    --user "${R2_ACCESS_KEY_ID}:${R2_SECRET_ACCESS_KEY}" \
    -H "Content-Type: $content_type" \
    --data-binary "@$file_path")

  if [ "$response" == "200" ]; then
    if [ -n "$R2_PUBLIC_BASE_URL" ]; then
      links+=("${R2_PUBLIC_BASE_URL}/${file_name}")
    else
      links+=("${ENDPOINT}/${R2_BUCKET_NAME}/${file_name}")
    fi
  else
    links+=("Failed: $original_name (HTTP $response)")
  fi

done <<< "$file_list"

printf '%s\n' "${links[@]}"

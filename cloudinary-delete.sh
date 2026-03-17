#!/usr/bin/env bash
# cloudinary-delete.sh — Delete file(s) from Cloudinary by public_id
# Trigger: :cloudinarydelete

source "$HOME/espanso-utility/shared.sh"

file_list=$(_clip_read)
if [ -z "$file_list" ]; then
  printf 'No file in clipboard'
  exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
get_resource_type() {
  local ext="${1##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  case "$ext" in
    mp4|mov|avi|mkv|webm) echo "video" ;;
    pdf|zip|txt|json|csv|docx|xlsx|html|htm|xml|pptx|doc|xls|ts|js|py|sh|ps1|sql|md|yaml|yml) echo "raw" ;;
    *) echo "image" ;;
  esac
}

sha1_hex() {
  echo -n "$1" | openssl sha1 | awk '{print $2}'
}

# ── Delete each file ──────────────────────────────────────────────────────────
results=()

while IFS= read -r file_path; do
  file_path=$(echo "$file_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$file_path" ] && continue

  filename=$(basename "$file_path")
  ext="${filename##*.}"
  resource_type=$(get_resource_type "$filename")

  # raw keeps full filename, image/video strips extension
  if [ "$resource_type" == "raw" ]; then
    public_id="$filename"
  else
    public_id="${filename%.*}"
  fi

  timestamp=$(date +%s)
  sig_string="public_id=${public_id}&timestamp=${timestamp}${CLOUDINARY_API_SECRET}"
  signature=$(sha1_hex "$sig_string")

  response=$(curl -s -X POST \
    "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/$resource_type/destroy" \
    -F "public_id=$public_id" \
    -F "timestamp=$timestamp" \
    -F "api_key=$CLOUDINARY_API_KEY" \
    -F "signature=$signature")

  result=$(echo "$response" | jq -r '.result // empty')

  if [ "$result" == "ok" ]; then
    results+=("Deleted: $public_id")
  else
    results+=("Failed: $public_id ($result)")
  fi

done <<< "$file_list"

printf '%s\n' "${results[@]}"

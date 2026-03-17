#!/usr/bin/env bash
# r2-delete.sh — Delete file(s) from R2 matching clipboard filename(s)
# Trigger: :r2delete

source "$HOME/espanso-utility/shared.sh"

ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

file_list=$(_clip_read)
if [ -z "$file_list" ]; then
  printf 'No file in clipboard'
  exit 1
fi

results=()

while IFS= read -r file_path; do
  file_path=$(echo "$file_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$file_path" ] && continue

  file_name=$(basename "$file_path")

  response=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
    "${ENDPOINT}/${R2_BUCKET_NAME}/${file_name}" \
    --aws-sigv4 "aws:amz:auto:s3" \
    --user "${R2_ACCESS_KEY_ID}:${R2_SECRET_ACCESS_KEY}")

  if [ "$response" == "204" ]; then
    results+=("Deleted: $file_name")
  else
    results+=("Failed: $file_name (HTTP $response)")
  fi

done <<< "$file_list"

printf '%s\n' "${results[@]}"

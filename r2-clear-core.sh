#!/usr/bin/env bash
# r2-clear-core.sh — Delete R2 objects older than N days (0 = all)
# Usage: r2-clear-core.sh <days>
# Trigger: :r2-clear-all / :r2-N-clear

source "$HOME/espanso-utility/shared.sh"

OLDER_THAN_DAYS="${1:-0}"
ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

# ── List all objects ──────────────────────────────────────────────────────────
response=$(curl -s \
  "${ENDPOINT}/${R2_BUCKET_NAME}" \
  --aws-sigv4 "aws:amz:auto:s3" \
  --user "${R2_ACCESS_KEY_ID}:${R2_SECRET_ACCESS_KEY}")

# Parse keys and dates from XML
keys=$(echo "$response" | grep -o '<Key>[^<]*</Key>' | sed 's/<Key>//;s/<\/Key>//')
dates=$(echo "$response" | grep -o '<LastModified>[^<]*</LastModified>' | sed 's/<LastModified>//;s/<\/LastModified>//')

if [ -z "$keys" ]; then
  printf 'No objects found in bucket'
  exit 0
fi

# Calculate cutoff
if [ "$OLDER_THAN_DAYS" -gt 0 ]; then
  cutoff=$(date -u -d "-${OLDER_THAN_DAYS} days" +%s 2>/dev/null || \
           date -u -v "-${OLDER_THAN_DAYS}d" +%s)
else
  cutoff=0
fi

total_deleted=0

# Combine keys and dates
paste <(echo "$keys") <(echo "$dates") | while IFS=$'\t' read -r key date; do
  should_delete=true

  if [ "$cutoff" -gt 0 ]; then
    created_epoch=$(date -u -d "$date" +%s 2>/dev/null || \
                    date -u -j -f "%Y-%m-%dT%H:%M:%S" "${date%.*}" +%s)
    [ "$created_epoch" -ge "$cutoff" ] && should_delete=false
  fi

  if [ "$should_delete" == "true" ]; then
    result=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
      "${ENDPOINT}/${R2_BUCKET_NAME}/${key}" \
      --aws-sigv4 "aws:amz:auto:s3" \
      --user "${R2_ACCESS_KEY_ID}:${R2_SECRET_ACCESS_KEY}")

    if [ "$result" == "204" ]; then
      ((total_deleted++))
      echo "Deleted: $key"
    else
      echo "Failed: $key (HTTP $result)"
    fi
  fi
done

if [ "$OLDER_THAN_DAYS" -gt 0 ]; then
  label="older than ${OLDER_THAN_DAYS} day(s)"
else
  label="all"
fi

printf "Done — deleted %d object(s) (%s) from R2" "$total_deleted" "$label"

#!/usr/bin/env bash
# cloudinary-clear-core.sh — Delete Cloudinary resources older than N days (0 = all)
# Usage: cloudinary-clear-core.sh <days>
# Trigger: :cloudinary-clear-all / :cloudinary-N-clear

source "$HOME/espanso-utility/shared.sh"

OLDER_THAN_DAYS="${1:-0}"

sha1_hex() {
  echo -n "$1" | openssl sha1 | awk '{print $2}'
}

# ── Get all resources of a type ───────────────────────────────────────────────
get_all_resources() {
  local resource_type="$1"
  local next_cursor=""
  local all_resources="[]"

  while true; do
    local qs="max_results=500"
    [ -n "$next_cursor" ] && qs="${qs}&next_cursor=${next_cursor}"

    local response
    response=$(curl -s -u "${CLOUDINARY_API_KEY}:${CLOUDINARY_API_SECRET}" \
      "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/resources/${resource_type}?${qs}")

    local error
    error=$(echo "$response" | jq -r '.error.message // empty')
    if [ -n "$error" ]; then
      echo "API Error ($resource_type): $error" >&2
      return
    fi

    local batch
    batch=$(echo "$response" | jq '.resources // []')
    all_resources=$(echo "$all_resources $batch" | jq -s 'add')

    next_cursor=$(echo "$response" | jq -r '.next_cursor // empty')
    [ -z "$next_cursor" ] && break
  done

  echo "$all_resources"
}

# ── Delete a single resource ──────────────────────────────────────────────────
delete_resource() {
  local public_id="$1"
  local resource_type="$2"

  local timestamp
  timestamp=$(date +%s)
  local sig_string="public_id=${public_id}&timestamp=${timestamp}${CLOUDINARY_API_SECRET}"
  local signature
  signature=$(sha1_hex "$sig_string")

  local response
  response=$(curl -s -X POST \
    "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/$resource_type/destroy" \
    -F "public_id=$public_id" \
    -F "timestamp=$timestamp" \
    -F "api_key=$CLOUDINARY_API_KEY" \
    -F "signature=$signature")

  echo "$response" | jq -r '.result // empty'
}

# ── Main ──────────────────────────────────────────────────────────────────────
total_deleted=0

# Calculate cutoff timestamp
if [ "$OLDER_THAN_DAYS" -gt 0 ]; then
  cutoff=$(date -u -d "-${OLDER_THAN_DAYS} days" +%s 2>/dev/null || \
           date -u -v "-${OLDER_THAN_DAYS}d" +%s)
else
  cutoff=0
fi

for resource_type in image video raw; do
  resources=$(get_all_resources "$resource_type")
  count=$(echo "$resources" | jq 'length')
  echo "Found $count $resource_type resource(s)..."

  while IFS= read -r resource; do
    public_id=$(echo "$resource" | jq -r '.public_id')
    created_at=$(echo "$resource" | jq -r '.created_at')
    created_epoch=$(date -u -d "$created_at" +%s 2>/dev/null || \
                    date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s)

    should_delete=true
    if [ "$cutoff" -gt 0 ] && [ "$created_epoch" -ge "$cutoff" ]; then
      should_delete=false
    fi

    if [ "$should_delete" == "true" ]; then
      result=$(delete_resource "$public_id" "$resource_type")
      if [ "$result" == "ok" ]; then
        ((total_deleted++))
      else
        echo "Failed: $public_id ($result)"
      fi
    fi
  done < <(echo "$resources" | jq -c '.[]')
done

if [ "$OLDER_THAN_DAYS" -gt 0 ]; then
  label="older than ${OLDER_THAN_DAYS} day(s)"
else
  label="all"
fi

printf "Deleted %d resource(s) (%s) from Cloudinary" "$total_deleted" "$label"

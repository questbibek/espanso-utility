#!/usr/bin/env bash
# create-meeting.sh — Creates Google Meet links using Google Calendar API
# Trigger: :meeting

source "$HOME/espanso-utility/shared.sh"

SCRIPT_DIR="$HOME/espanso-utility"
CREDENTIALS_PATH="$SCRIPT_DIR/google-credentials.json"
TOKEN_PATH="$SCRIPT_DIR/google-token.json"
TITLE="${1:-Quick Meeting}"
DURATION="${2:-60}"
DATETIME="${3:-}"

# Check credentials
if [ ! -f "$CREDENTIALS_PATH" ]; then
  printf 'ERROR: google-credentials.json not found.'
  exit 1
fi

# Read credentials
CLIENT_ID=$(jq -r '.installed.client_id' "$CREDENTIALS_PATH")
CLIENT_SECRET=$(jq -r '.installed.client_secret' "$CREDENTIALS_PATH")
REDIRECT_URI="http://localhost"

# ── Get Access Token ──────────────────────────────────────────────────────────
get_access_token() {
  if [ -f "$TOKEN_PATH" ]; then
    EXPIRY=$(jq -r '.expiry_time' "$TOKEN_PATH")
    NOW=$(date -u +%s)
    EXPIRY_EPOCH=$(date -u -d "$EXPIRY" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$EXPIRY" +%s 2>/dev/null)

    if [ "$EXPIRY_EPOCH" -gt "$NOW" ]; then
      jq -r '.access_token' "$TOKEN_PATH"
      return
    fi

    # Refresh token
    REFRESH_TOKEN=$(jq -r '.refresh_token' "$TOKEN_PATH")
    RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
      -d "client_id=$CLIENT_ID" \
      -d "client_secret=$CLIENT_SECRET" \
      -d "refresh_token=$REFRESH_TOKEN" \
      -d "grant_type=refresh_token")

    ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
    EXPIRES_IN=$(echo "$RESPONSE" | jq -r '.expires_in')
    EXPIRY_TIME=$(date -u -d "+${EXPIRES_IN} seconds" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v "+${EXPIRES_IN}S" +%Y-%m-%dT%H:%M:%SZ)

    jq --arg at "$ACCESS_TOKEN" --arg et "$EXPIRY_TIME" \
      '.access_token = $at | .expiry_time = $et' "$TOKEN_PATH" > /tmp/token_tmp.json
    mv /tmp/token_tmp.json "$TOKEN_PATH"

    echo "$ACCESS_TOKEN"
    return
  fi

  # First-time auth
  AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth?client_id=$CLIENT_ID&redirect_uri=$REDIRECT_URI&response_type=code&scope=https://www.googleapis.com/auth/calendar"

  # Open browser
  if command -v xdg-open &>/dev/null; then
    xdg-open "$AUTH_URL"
  elif command -v open &>/dev/null; then
    open "$AUTH_URL"
  fi

  echo "Opening browser for authentication..." >&2
  read -rp "Paste the authorization code from the URL: " AUTH_CODE

  RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
    -d "code=$AUTH_CODE" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "redirect_uri=$REDIRECT_URI" \
    -d "grant_type=authorization_code")

  ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
  REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh_token')
  EXPIRES_IN=$(echo "$RESPONSE" | jq -r '.expires_in')
  EXPIRY_TIME=$(date -u -d "+${EXPIRES_IN} seconds" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v "+${EXPIRES_IN}S" +%Y-%m-%dT%H:%M:%SZ)

  jq -n \
    --arg at "$ACCESS_TOKEN" \
    --arg rt "$REFRESH_TOKEN" \
    --arg et "$EXPIRY_TIME" \
    '{access_token: $at, refresh_token: $rt, expiry_time: $et}' > "$TOKEN_PATH"

  echo "$ACCESS_TOKEN"
}

# ── Build Event Times ─────────────────────────────────────────────────────────
if [ -z "$DATETIME" ]; then
  START_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  END_TIME=$(date -u -d "+${DURATION} minutes" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v "+${DURATION}M" +%Y-%m-%dT%H:%M:%SZ)
else
  START_TIME=$(date -u -d "$DATETIME" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -j -f "%m-%d-%Y %I:%M %p" "$DATETIME" +%Y-%m-%dT%H:%M:%SZ)
  END_TIME=$(date -u -d "$DATETIME +${DURATION} minutes" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v "+${DURATION}M" +%Y-%m-%dT%H:%M:%SZ)
fi

REQUEST_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)

# ── Create Event ──────────────────────────────────────────────────────────────
ACCESS_TOKEN=$(get_access_token)

RESPONSE=$(curl -s -X POST \
  "https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1&sendUpdates=all" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg title "$TITLE" \
    --arg start "$START_TIME" \
    --arg end "$END_TIME" \
    --arg rid "$REQUEST_ID" \
    '{
      summary: $title,
      start: {dateTime: $start, timeZone: "UTC"},
      end: {dateTime: $end, timeZone: "UTC"},
      conferenceData: {
        createRequest: {
          requestId: $rid,
          conferenceSolutionKey: {type: "hangoutsMeet"}
        }
      }
    }')")

MEET_LINK=$(echo "$RESPONSE" | jq -r '.conferenceData.entryPoints[] | select(.entryPointType=="video") | .uri')

if [ -n "$MEET_LINK" ]; then
  printf '%s' "$MEET_LINK"
else
  printf 'Error: %s' "$(echo "$RESPONSE" | jq -r '.error.message // "Failed to create meeting"')"
fi

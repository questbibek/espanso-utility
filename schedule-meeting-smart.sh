#!/usr/bin/env bash
# schedule-meeting-smart.sh — Smart meeting scheduler from clipboard
# Trigger: :schedule

source "$HOME/espanso-utility/shared.sh"

SCRIPT_DIR="$HOME/espanso-utility"
CREDENTIALS_PATH="$SCRIPT_DIR/google-credentials.json"
TOKEN_PATH="$SCRIPT_DIR/google-token.json"

sleep 0.05
text=$(_clip_read)
if [ -z "$text" ]; then
  printf 'ERROR: No text in clipboard'
  exit 1
fi

# Check credentials
if [ ! -f "$CREDENTIALS_PATH" ]; then
  printf 'ERROR: google-credentials.json not found. Run create-meeting first.'
  exit 1
fi

CLIENT_ID=$(jq -r '.installed.client_id' "$CREDENTIALS_PATH")
CLIENT_SECRET=$(jq -r '.installed.client_secret' "$CREDENTIALS_PATH")

CURRENT_DATE=$(date '+%Y-%m-%d %H:%M')
TOMORROW=$(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d')
TIMEZONE=$(cat /etc/timezone 2>/dev/null || echo "UTC")

# ── Step 1: Extract meeting details via GPT ───────────────────────────────────
gpt_response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    --arg date "$CURRENT_DATE" \
    --arg tomorrow "$TOMORROW" \
    --arg tz "$TIMEZONE" \
    '{
      model: "gpt-4o-mini",
      temperature: 0.3,
      messages: [
        {role: "system", content: ("Extract meeting details and return ONLY valid JSON:\n{\n  \"title\": \"Meeting title\",\n  \"emails\": [\"email1@example.com\"],\n  \"datetime\": \"YYYY-MM-DD HH:MM\",\n  \"duration\": 60\n}\n\nRULES:\n- datetime REQUIRED in format YYYY-MM-DD HH:MM (24-hour)\n- Current datetime: " + $date + "\n- Current timezone: " + $tz + "\n- Parse relative times from NOW\n- in 15 minutes = add 15 minutes to current time\n- in 1 hour = add 1 hour to current time\n- tomorrow = " + $tomorrow + "\n- emails: array of email addresses (empty [] if none)\n- duration: minutes (default 60)\n- title: descriptive subject\n- Return ONLY JSON, no markdown, no explanation")},
        {role: "user", content: $text}
      ]
    }')")

json=$(echo "$gpt_response" | jq -r '.choices[0].message.content // empty' | sed 's/```json//g' | sed 's/```//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$json" ]; then
  printf 'ERROR: Failed to parse meeting details'
  exit 1
fi

TITLE=$(echo "$json" | jq -r '.title')
DATETIME=$(echo "$json" | jq -r '.datetime')
DURATION=$(echo "$json" | jq -r '.duration // 60')
EMAILS=$(echo "$json" | jq -r '.emails[]?' 2>/dev/null)

if [ -z "$DATETIME" ] || [ "$DATETIME" == "null" ]; then
  printf 'ERROR: No date/time specified. Use :meeting for instant meetings.'
  exit 1
fi

# ── Step 2: Get Access Token ──────────────────────────────────────────────────
get_access_token() {
  if [ -f "$TOKEN_PATH" ]; then
    EXPIRY=$(jq -r '.expiry_time' "$TOKEN_PATH")
    NOW=$(date -u +%s)
    EXPIRY_EPOCH=$(date -u -d "$EXPIRY" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$EXPIRY" +%s 2>/dev/null)

    if [ "$EXPIRY_EPOCH" -gt "$NOW" ]; then
      jq -r '.access_token' "$TOKEN_PATH"
      return
    fi

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

  printf 'ERROR: Not authenticated. Run :meeting first to authenticate.'
  exit 1
}

# ── Step 3: Build Event ───────────────────────────────────────────────────────
ACCESS_TOKEN=$(get_access_token)

START_TIME=$(date -u -d "$DATETIME" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -j -f "%Y-%m-%d %H:%M" "$DATETIME" +%Y-%m-%dT%H:%M:%SZ)
END_TIME=$(date -u -d "$DATETIME +${DURATION} minutes" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v "+${DURATION}M" +%Y-%m-%dT%H:%M:%SZ)
REQUEST_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)

# Build attendees array
ATTENDEES_JSON="[]"
if [ -n "$EMAILS" ]; then
  ATTENDEES_JSON=$(echo "$EMAILS" | jq -R '{"email": .}' | jq -s '.')
fi

RESPONSE=$(curl -s -X POST \
  "https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1&sendUpdates=all" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg title "$TITLE" \
    --arg start "$START_TIME" \
    --arg end "$END_TIME" \
    --arg rid "$REQUEST_ID" \
    --argjson attendees "$ATTENDEES_JSON" \
    '{
      summary: $title,
      start: {dateTime: $start, timeZone: "UTC"},
      end: {dateTime: $end, timeZone: "UTC"},
      attendees: $attendees,
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

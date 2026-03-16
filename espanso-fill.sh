#!/usr/bin/env bash
# espanso-fill.sh — Form filler with realistic fake data
# Trigger: :fill

source "$HOME/espanso-utility/shared.sh"

sleep 0.05
text=$(_clip_read)
[ -z "$text" ] && exit 0

CURRENT_DATE=$(date '+%Y-%m-%d')
CURRENT_TIME=$(date '+%H:%M')
RANDOM_SEED=$RANDOM$RANDOM$RANDOM

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    --arg date "$CURRENT_DATE" \
    --arg time "$CURRENT_TIME" \
    --arg seed "$RANDOM_SEED" \
    '{
      model: "gpt-4o-mini",
      temperature: 1,
      max_tokens: 100,
      messages: [
        {role: "system", content: ("Random seed for this request: " + $seed + ". Use this to ensure uniqueness.\nToday is " + $date + " and current time is " + $time + ".\nYou are a form filler assistant for testing purposes. Generate realistic random/fake values — never repeat the same values across calls.\nRULES:\n- Return ONLY the raw value — no explanation, no quotes, no punctuation\n- Every call MUST return different values — use the seed to vary your output\n- First Name → random first name, vary ethnicity and origin (not always Western)\n- Last Name → random last name, vary ethnicity\n- Full Name → random full name\n- Email → random fake email @mailinator.com\n- Phone → random US-format +1-555-xxx-xxxx\n- Username → creative random username\n- Company → random fake company name\n- Job Title → random realistic job title\n- Website → random fake domain\n- Address → random fake US street address\n- City → random US city\n- State → random US state abbreviation\n- Country → vary between US, UK, Canada, Australia\n- ZIP → random US ZIP\n- Date of Birth → random DOB aged 18-60, vary year month and day\n- Gender → vary between Male, Female, Non-binary\n- Card Number → fake Visa: 4xxx xxxx xxxx xxxx\n- CVV → random 3-digit\n- Card Expiry → future MM/YY\n- OTP / Code → random 4-6 digits\n- Password → random strong 12-char mixed password\n- Date → todays date\n- Time → current time\n- Unknown → sensible random value")},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to fill"')"
fi

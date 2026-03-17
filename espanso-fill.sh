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
      max_tokens: 200,
      messages: [
        {role: "system", content: ("Random seed: " + $seed + ". Today: " + $date + ". Time: " + $time + ".\n\nYou are a form filler for testing. Generate realistic fake values.\n\nCORE RULES:\n- Return ONLY the raw value — no explanation, no quotes, no extra text\n- Every call MUST return different values using the seed\n- ALWAYS read the user input carefully for any hints or context\n\nLOCATION RULES:\n- If a specific city, country or region is mentioned → generate ALL location-related data (address, city, state, ZIP, phone format, names) consistent with that location\n- If no location mentioned → use any random country, vary globally\n\nCARD RULES:\n- If user mentions a specific card type (Visa, MasterCard, Amex, Discover, Western Union, etc.) → generate that exact card type with correct format and prefix\n- Visa → starts with 4\n- MasterCard → starts with 51-55\n- Amex → starts with 34 or 37, 15 digits\n- Discover → starts with 6011\n- If no card type mentioned → use any random card type\n\nOTHER RULES:\n- Phone → match location format if location given, otherwise random international\n- Names → match cultural context of location if given\n- Date of Birth → random aged 18-60\n- Gender → vary between Male, Female, Non-binary\n- Email → @mailinator.com\n- Password → strong 12-char mixed\n- OTP/Code → random 4-6 digits\n- Date → todays actual date\n- Time → current actual time\n- Unknown fields → sensible random value matching any context clues in the input")},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to fill"')"
fi

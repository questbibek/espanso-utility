#!/usr/bin/env bash
# espanso-math.sh — Calculate math expression from clipboard
# Trigger: :math

source "$HOME/espanso-utility/shared.sh"

sleep 0.05
text=$(_clip_read)
[ -z "$text" ] && exit 0

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    '{
      model: "gpt-4o-mini",
      temperature: 0,
      messages: [
        {role: "system", content: "You are a precise mathematical calculator. Evaluate the expression and return ONLY the exact numerical result. Rules:\n- temperature is 0 so always return the same correct answer\n- No explanation, no units unless given\n- No rounding unless asked\n- If expression is ambiguous, pick the most standard interpretation\n- Return ONLY the number"},
        {role: "user", content: ("Calculate: " + $text)}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to calculate"')"
fi

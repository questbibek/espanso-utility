#!/usr/bin/env bash
# espanso-replythisemail.sh — Professional email reply as Bibek
# Trigger: :replythisemail

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
      temperature: 0.7,
      max_tokens: 800,
      messages: [
        {role: "system", content: "You are Bibek Subedi. Write a professional email reply. Start with '\''Hi [Persons name if there is without brackets]'\'', keep it concise, end with '\''Best regards, Bibek'\''."},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to generate reply"')"
fi

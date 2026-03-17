#!/usr/bin/env bash
# draft-email.sh — Draft professional email from clipboard context
# Trigger: :draft

source "$HOME/espanso-utility/shared.sh"

sleep 0.05
text=$(_clip_read)
if [ -z "$text" ]; then
  printf 'ERROR: No context in clipboard'
  exit 1
fi

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    '{
      model: "gpt-4o-mini",
      temperature: 0.7,
      messages: [
        {role: "system", content: "You are a professional email writer. Draft a clear, professional email based on the context provided.\nGuidelines:\n- Include subject line\n- Professional but friendly tone\n- Clear and concise\n- Proper email structure (greeting, body, closing)\n- No fluff or unnecessary words\nFormat:\nSubject: [subject line]\n\n[Email body]\n\nBest regards,\nBibek"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error drafting email"')"
fi

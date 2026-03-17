#!/usr/bin/env bash
# word-meaning.sh — Quick one-line word definition from clipboard
# Trigger: :meaning

source "$HOME/espanso-utility/shared.sh"

sleep 0.05
text=$(_clip_read)
if [ -z "$text" ]; then
  printf 'ERROR: No word in clipboard'
  exit 1
fi

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    '{
      model: "gpt-4o-mini",
      temperature: 0.3,
      messages: [
        {role: "system", content: "Provide a SHORT, CONCISE definition of the word. Format:\n[word] ([part of speech]) - [one-line definition]\nExample: ephemeral (adj.) - lasting for a very short time\nKeep it to ONE line. Be clear and practical."},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error getting definition"')"
fi

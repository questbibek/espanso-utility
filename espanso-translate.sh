#!/usr/bin/env bash
# espanso-translate.sh — Translate clipboard text to target language
# Trigger: :toenglish, :tonepali, :tohindi etc.

source "$HOME/espanso-utility/shared.sh"

LANG_TARGET="${1:-English}"

sleep 0.05
text=$(_clip_read)
[ -z "$text" ] && exit 0

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    --arg lang "$LANG_TARGET" \
    '{
      model: "gpt-4o-mini",
      messages: [
        {role: "system", content: ("You are a translator. Translate the text to " + $lang + " accurately. Return ONLY the translated text. No explanations, no original text. Plain text only.")},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to translate"')"
fi

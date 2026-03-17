#!/usr/bin/env bash
# word-full-meaning.sh — Comprehensive word analysis from clipboard
# Trigger: :fullmeaning

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
        {role: "system", content: "Provide a COMPREHENSIVE analysis of the word. Use DOUBLE line breaks between sections for readability:\n\nWORD: [word]\n\nPRONUNCIATION: [SYL-la-ble format, e.g., SEN-si-tiv]\n\nPART OF SPEECH: [noun/verb/adjective/etc.]\n\nDEFINITIONS:\n1. [First definition]\n2. [Second definition if applicable]\n\nSYNONYMS: [list synonyms]\n\nANTONYMS: [list antonyms]\n\nUSAGE EXAMPLES:\n- [Example sentence 1]\n- [Example sentence 2]\n- [Example sentence 3]\n\nETYMOLOGY: [Brief origin of the word]\n\nCOMMON PHRASES:\n- [Phrase 1]\n- [Phrase 2]\n\nIMPORTANT:\n- Use simple syllable-based pronunciation (SEN-si-tiv) NOT IPA symbols\n- Use TWO newlines between major sections\n- Keep it clear and well-spaced for readability"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error getting full definition"')"
fi

#!/usr/bin/env bash
# espanso-allbugtask.sh — Select all, format as bug report, replace
# Trigger: :allbugtask

source "$HOME/espanso-utility/shared.sh"

sleep 0.2
_select_all
_copy

text=$(_clip_read)
[ -z "$text" ] && exit 0

text=$(echo "$text" | sed 's/:allbugtask[[:space:]]*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
[ -z "$text" ] && exit 0

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    '{
      model: "gpt-4o-mini",
      temperature: 0.3,
      max_tokens: 1000,
      messages: [
        {role: "system", content: "You are a bug report formatter. Convert the input into a properly structured bug report.\n\nFORMAT:\nBug Title: [Clear, concise title]\n\nDescription:\n[Brief description of the bug]\n\nSteps to Reproduce:\n1. [First step]\n2. [Second step]\n3. [Third step]\n\nExpected Behavior:\n[What should happen]\n\nActual Behavior:\n[What actually happens]\n\nPriority: [Critical/High/Medium/Low]\n\nEnvironment:\n- Browser/Device: [if applicable]\n- OS: [if applicable]\n- Version: [if applicable]\n\nRULES:\n- Extract information from the input\n- If information is missing, mark as [To be determined]\n- Keep it concise and professional\n- Infer priority based on severity if not mentioned\n- Do NOT use markdown formatting\n- Use clear spacing and line breaks\n- Avoid emojis\n- Use ASCII characters only"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  _select_all
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error formatting bug report"')"
fi

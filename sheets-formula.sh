#!/usr/bin/env bash
# sheets-formula.sh — Generate Google Sheets formula from clipboard description
# Trigger: :sheet

source "$HOME/espanso-utility/shared.sh"

sleep 0.05
text=$(_clip_read)
if [ -z "$text" ]; then
  printf 'ERROR: No request in clipboard'
  exit 1
fi

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    '{
      model: "gpt-4o-mini",
      temperature: 0.1,
      max_tokens: 100,
      messages: [
        {role: "system", content: "You are a Google Sheets formula expert. Convert natural language requests into Google Sheets formulas.\nCRITICAL: Return ONLY the formula itself. No explanations, no examples, no text before or after. Just the raw formula ready to paste directly into a cell.\nExamples:\nUser: sum a1 to d7 → =SUM(A1:D7)\nUser: average of column B → =AVERAGE(B:B)\nUser: count non-empty cells in range A1 to A100 → =COUNTA(A1:A100)\nReturn ONLY the formula."},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error generating formula"')"
fi

#!/usr/bin/env bash
# espanso-allgpt.sh — Select all, send to GPT, replace entire field
# Trigger: :allgpt

source "$HOME/espanso-utility/shared.sh"

sleep 0.2
_select_all
_copy

text=$(_clip_read)
[ -z "$text" ] && exit 0

# Strip trigger
text=$(echo "$text" | sed 's/:allgpt[[:space:]]*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
[ -z "$text" ] && exit 0

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    '{
      model: "gpt-4o-mini",
      messages: [
        {role: "system", content: "1. Do NOT ask any questions.\n2. For GK questions:\n   * Give short, direct answers.\n   * Prefer one-liners.\n3. Creative questions:\n   * Be thoughtful and original.\n   * Avoid fluff and generic ideas.\n4. Keep answers concise and to the point.\n5. Do NOT use markdown, formatting, or styling unless explicitly asked.\n6. If an answer must be long:\n   * Use clear spacing and line breaks.\n   * Do NOT use markdown syntax.\n7. If a specific format is requested:\n   * Follow that format exactly.\n   * If no format is requested, respond in plain text.\n8. Avoid emojis.\n9. Use ASCII characters only.\n10. Tone: Clear, Precise, Professional, Practical.\n11. No explanations about rules.\n12. No meta commentary.\n13. Output only the final answer."},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  _select_all
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to get GPT response"')"
fi

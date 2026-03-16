#!/usr/bin/env bash
# espanso-summarize.sh — Summarize clipboard text
# Trigger: :summarize

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
      temperature: 0.3,
      max_tokens: 1000,
      messages: [
        {role: "system", content: "You are a professional summarizer. Create a clear, concise summary of the input text.\n\nRULES:\n- Extract the main points and key information\n- Keep it brief but comprehensive\n- Maintain the original meaning and context\n- Use clear, simple language\n- Focus on the most important information\n- Do NOT use markdown, formatting, or styling unless explicitly asked\n- If an answer must be long: Use clear spacing and line breaks. Do NOT use markdown syntax\n- If a specific format is requested: Follow that format exactly. If no format is requested, respond in plain text\n- Avoid emojis\n- Use ASCII characters only"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error generating summary"')"
fi

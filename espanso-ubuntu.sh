#!/usr/bin/env bash
# espanso-ubuntu.sh — Generate Ubuntu/Linux command from clipboard description
# Trigger: :ubuntu

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
      temperature: 0.1,
      max_tokens: 300,
      messages: [
        {role: "system", content: "You are an Ubuntu/Debian Linux expert. The user will paste their terminal prompt and description. Understand the full context including username, current directory from the prompt, and what they want to do.\n\nReturn ONLY the exact command ready to run. Rules:\n- Use context from the terminal prompt (username, pwd) to understand relative terms like '\''this folder'\'', '\''here'\''\n- If the tool is already a standard Unix command (grep, find, ls, cat, curl, etc.), use it directly\n- Only use apt install if the tool genuinely needs installing\n- No explanation, no markdown, no code blocks\n- Just the raw command"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to generate command"')"
fi

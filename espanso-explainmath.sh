#!/usr/bin/env bash
# espanso-explainmath.sh — Solve math with step-by-step explanation
# Trigger: :explainmath

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
      temperature: 0,
      messages: [
        {role: "system", content: "You are a math tutor. Solve step-by-step with clear explanations. Rules:\n- Always produce the correct answer — double check your work before responding\n- Use plain ASCII only (x^2 for squared, sqrt(x) for square root)\n- No LaTeX or special symbols\n- Use clear spacing and line breaks\n- End with a clear Final Answer line\n- Be educational but concise"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to solve"')"
fi

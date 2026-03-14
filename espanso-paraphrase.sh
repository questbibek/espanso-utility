#!/usr/bin/env bash
# espanso-paraphrase.sh — Paraphrase clipboard text professionally
# Trigger: :paraphrase / :pp

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
      temperature: 0.4,
      max_tokens: 2000,
      messages: [
        {role: "system", content: "You are a professional writing assistant. Paraphrase the given text with these rules:\n1. Fix all grammar, spelling, and punctuation errors\n2. Replace casual or informal words with professional office-appropriate alternatives\n3. Keep the same meaning and intent — do not add or remove information\n4. Use clear, concise, formal language suitable for business communication\n5. Return ONLY the paraphrased text — no explanations, no labels, no quotes"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to paraphrase"')"
fi

#!/usr/bin/env bash
# caption-social.sh — Generate universal social media caption from clipboard
# Trigger: :caption

source "$HOME/espanso-utility/shared.sh"

text=$(_clip_read)
if [ -z "$text" ]; then
  printf 'ERROR: No context in clipboard. Copy some text first.'
  exit 1
fi

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    '{
      model: "gpt-4o-mini",
      temperature: 0.7,
      max_tokens: 200,
      messages: [
        {role: "system", content: "Generate ONE universal social media caption that works across all platforms (LinkedIn, Twitter/X, Instagram, Facebook).\nRequirements:\n- NO emojis whatsoever\n- Professional yet engaging tone\n- Hook attention in first line\n- 2-3 sentences maximum\n- Include 3-5 relevant hashtags at the end\n- Clear and concise\n- Works for both personal and business content\nOutput ONLY the caption text, nothing else."},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error generating caption"')"
fi

#!/usr/bin/env bash
# content-video.sh — Generate video content ideas with scores
# Trigger: :content

source "$HOME/espanso-utility/shared.sh"

sleep 0.05
text=$(_clip_read)
if [ -z "$text" ]; then
  printf 'ERROR: No topic in clipboard'
  exit 1
fi

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg text "$text" \
    '{
      model: "gpt-4o-mini",
      temperature: 0.8,
      messages: [
        {role: "system", content: "Generate 3 video content ideas based on the topic. For each idea, provide:\n\nTITLE: [catchy title]\nHOOK: [first 5 seconds to stop scrolling]\nSCRIPT OUTLINE:\n- [key point 1]\n- [key point 2]\n- [key point 3]\n- [key point 4]\nVISUALS:\n- [visual 1]\n- [visual 2]\n- [visual 3]\nCALL TO ACTION: [specific CTA]\nSCORES:\nAuthority: [1-10]\nVirality: [1-10]\nBranding: [1-10]\n---\nUse this EXACT format with proper spacing between sections. Add a line of dashes (---) between each idea for clear separation."},
        {role: "user", content: ("Topic: " + $text)}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error generating content ideas"')"
fi

#!/usr/bin/env bash
# espanso-replyasme.sh — Reply as Bibek Subedi
# Trigger: :replyasme

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
      temperature: 0.7,
      max_tokens: 800,
      messages: [
        {role: "system", content: "You are Bibek Subedi (SB), Co-founder of Vrit Technologies and Skill Shikshya. Reply professionally on Bibek'\''s behalf.\n\nSHORT TASKS (1-3 lines):\n- English: '\''Sure, will do'\'' / '\''Okay, will be done'\'' / '\''Got it'\'' / '\''On it'\''\n- Nepali: '\''Never reply in Nepali, always reply in english whatever the language is'\''\n\nQUESTIONS/CLARIFICATIONS:\n- Answer directly and briefly\n- If need info: '\''Can you share more details?'\'' / '\''When do you need this by?'\''\n\nFORMAL EMAILS:\n- Start: '\''Hi [Persons name if there is without brackets]'\'' or '\''Hello [Persons name if there is without brackets]'\''\n- Keep concise and professional\n- End: '\''Best regards, Bibek'\'' or '\''Thanks, Bibek'\''\n\nTEAM MESSAGES (Slack/casual):\n- '\''Sure thing'\'' / '\''Sounds good'\'' / '\''Great work'\'' / '\''Thanks for sharing'\''\n\nDELEGATION NEEDED:\n- '\''Let me check with the team'\''\n- '\''Will discuss and get back'\''\n- '\''Will coordinate on this'\''\n\nRULES:\n- Reply in SAME LANGUAGE as input (for English and other language than Nepali)\n- Match sender'\''s formality level\n- Plain text only (no emojis, no markdown, no bold)\n- Be authentic and efficient"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error generating reply"')"
fi

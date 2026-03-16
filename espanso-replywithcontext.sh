#!/usr/bin/env bash
# espanso-replywithcontext.sh — Context-aware reply as Bibek
# Trigger: :replywithcontext / :rwc
# Usage: Copy the message to reply to, then type :rwc after some context text

source "$HOME/espanso-utility/shared.sh"

# Save the copied message (what to reply to)
copied_message=$(_clip_read)

# Clear clipboard
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "" | pbcopy
else
  echo "" | xclip -selection clipboard -i
fi

sleep 0.1

# Select all to get full context
_select_all
_copy
sleep 0.3

full_text=$(_clip_read)

if [ -z "$copied_message" ] || [ -z "$full_text" ]; then
  printf 'Error: No text copied or no clipboard content'
  exit 1
fi

# Split on trigger word to get context before it
context=$(echo "$full_text" | sed 's/:replywithcontext.*$//' | sed 's/:rwc.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
after=$(echo "$full_text" | grep -oP '(?::replywithcontext|:rwc)\s*\K.*' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$context" ]; then
  printf 'Error: Trigger not found in text'
  exit 1
fi

response=$(curl -s --max-time 30 https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$(jq -n \
    --arg context "$context" \
    --arg message "$copied_message" \
    '{
      model: "gpt-4o-mini",
      temperature: 0.7,
      max_tokens: 200,
      messages: [
        {role: "system", content: "You are Bibek Subedi (SB), Co-founder of Vrit Technologies. Write SHORT, PRECISE replies (1-3 sentences max). Be direct, professional, and relevant. No fluff. Plain text only."},
        {role: "user", content: ("Context: " + $context + "\n\nMessage to reply to: " + $message + "\n\nWrite a brief reply as Bibek considering the context above.")}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  if [ -n "$after" ]; then
    printf '%s %s' "$reply" "$after"
  else
    printf '%s' "$reply"
  fi
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to generate reply"')"
fi

#!/usr/bin/env bash
# espanso-alluserstory.sh — Select all, format as user story, replace
# Trigger: :alluserstory

source "$HOME/espanso-utility/shared.sh"

sleep 0.2
_select_all
_copy

text=$(_clip_read)
[ -z "$text" ] && exit 0

text=$(echo "$text" | sed 's/:alluserstory[[:space:]]*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
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
        {role: "system", content: "You are a user story formatter for project management. Convert the input into a properly structured user story.\n\nFORMAT:\nUser Story: As a [user type], I want to [action] so that [benefit]\n\nDescription:\n[Brief description of the feature/functionality]\n\nAcceptance Criteria:\n1. [Specific, testable criterion]\n2. [Specific, testable criterion]\n3. [Specific, testable criterion]\n\nPriority: [Critical/High/Medium/Low]\n\nEstimated Effort: [Story Points or Time estimate]\n\nNotes:\n[Any additional context, dependencies, or technical considerations]\n\nRULES:\n- Extract information from the input\n- Write clear, specific acceptance criteria\n- If information is missing, mark as [To be determined]\n- Keep it concise and actionable\n- Focus on user value and business outcomes\n- Infer priority based on business impact if not mentioned\n- Do NOT use markdown formatting\n- Use clear spacing and line breaks\n- Avoid emojis\n- Use ASCII characters only"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  _select_all
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error formatting user story"')"
fi

#!/usr/bin/env bash
# espanso-commit.sh — Generate git commit message from clipboard
# Trigger: :commit

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
      max_tokens: 300,
      messages: [
        {role: "system", content: "You are an expert at writing git commit messages. Given a git diff, list of changes, or description of what was done, generate a ready-to-run git command following these rules:\n1. Use Conventional Commits format: type(scope): short description\n2. Types: feat, fix, refactor, chore, docs, style, test, perf\n3. Subject line: max 72 chars, imperative mood, no period at end\n4. Return ONLY this exact format on a single line, nothing else:\n   git commit -m \"your message here\" ; git push\n\nExamples:\ngit commit -m \"feat(auth): add JWT refresh token rotation\" ; git push\ngit commit -m \"fix(payroll): handle clock-in during approved leave edge case\" ; git push\ngit commit -m \"refactor(api): extract email validation to separate service\" ; git push"},
        {role: "user", content: $text}
      ]
    }')")

reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$reply" ]; then
  printf '%s' "$reply"
else
  printf '%s' "$(echo "$response" | jq -r '.error.message // "Error: Unable to generate commit message"')"
fi

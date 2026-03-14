#!/usr/bin/env bash
# espanso-phone.sh — Random Nepal phone number (97xxxxxxxx or 98xxxxxxxx)
# Trigger: :phone / :npphone

prefix=$((RANDOM % 2 == 0 ? 97 : 98))
digits=$(shuf -i 0-9 -n 8 | tr -d '\n')
echo "${prefix}${digits}"

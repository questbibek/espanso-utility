#!/usr/bin/env bash
length=$((6 + RANDOM % 5))
username=$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c "$length")
echo "${username}@mailinator.com"

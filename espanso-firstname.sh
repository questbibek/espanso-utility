#!/usr/bin/env bash
names=(
  James John Robert Michael William David Richard Joseph Thomas Charles
  Christopher Daniel Matthew Anthony Mark Donald Steven Paul Andrew Joshua
  Kenneth Kevin Brian George Edward Ronald Timothy Jason Jeffrey Ryan
  Jacob Gary Nicholas Eric Jonathan Stephen Larry Justin Scott Brandon
  Frank Benjamin Gregory Samuel Raymond Patrick Alexander Jack Dennis Jerry
)
echo "${names[$RANDOM % ${#names[@]}]}"

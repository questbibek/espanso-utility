#!/usr/bin/env bash
# shared.sh — Sourced by all espanso-utility scripts
# Handles: .env loading, clipboard detection

# ── Load .env ─────────────────────────────────────────────────────────────────
source "$HOME/espanso-utility/.env"

# ── Clipboard ─────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  _clip_read()  { pbpaste; }
  _clip_write() { pbcopy; }
elif command -v wl-paste &>/dev/null; then
  _clip_read()  { wl-paste --no-newline; }
  _clip_write() { wl-copy; }
elif command -v xclip &>/dev/null; then
  _clip_read()  { xclip -selection clipboard -o; }
  _clip_write() { xclip -selection clipboard -i; }
elif command -v xsel &>/dev/null; then
  _clip_read()  { xsel --clipboard --output; }
  _clip_write() { xsel --clipboard --input; }
else
  echo "[ERROR] No clipboard tool found. Install xclip or wl-clipboard." >&2
  exit 1
fi

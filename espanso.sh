#!/usr/bin/env bash
# ==============================================================================
# Espanso Utility - Mac & Linux Installer
# ==============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    # Detect distro
    if [ -f /etc/debian_version ]; then
      DISTRO="debian"
    elif [ -f /etc/fedora-release ]; then
      DISTRO="fedora"
    elif [ -f /etc/arch-release ]; then
      DISTRO="arch"
    else
      DISTRO="other"
    fi
    # Detect display server
    SESSION="${XDG_SESSION_TYPE:-}"
    if [ -z "$SESSION" ]; then
      SESSION=$(loginctl show-session "$(loginctl | grep "$(whoami)" | awk '{print $1}')" -p Type --value 2>/dev/null || echo "x11")
    fi
  else
    error "Unsupported OS: $OSTYPE"
  fi
}

install_espanso_mac() {
  info "Installing Espanso on macOS..."
  if ! command -v brew &>/dev/null; then
    info "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew install --cask espanso

  # Set up auto-start via launchd (equivalent of Windows Task Scheduler)
  info "Setting up Espanso auto-start on login (launchd)..."
  PLIST_DIR="$HOME/Library/LaunchAgents"
  PLIST_FILE="$PLIST_DIR/com.espanso.espanso.plist"
  mkdir -p "$PLIST_DIR"
  cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.espanso.espanso</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Applications/Espanso.app/Contents/MacOS/espanso</string>
    <string>launcher</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/espanso.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/espanso.err</string>
</dict>
</plist>
EOF
  launchctl load "$PLIST_FILE"
  success "Espanso will now auto-start on every login (launchd)"
  success "Espanso installed via Homebrew"
}

install_espanso_linux() {
  info "Detected Linux distro: ${DISTRO}, display: ${SESSION}"

  if [[ "$DISTRO" == "debian" ]]; then
    if [[ "$SESSION" == "wayland" ]]; then
      DEB_URL="https://github.com/espanso/espanso/releases/latest/download/espanso-debian-wayland-amd64.deb"
    else
      DEB_URL="https://github.com/espanso/espanso/releases/latest/download/espanso-debian-x11-amd64.deb"
    fi
    info "Downloading Espanso .deb package..."
    wget -q -O /tmp/espanso.deb "$DEB_URL"
    sudo apt install -y /tmp/espanso.deb
    rm /tmp/espanso.deb
  else
    # AppImage fallback for Fedora, Arch, and others (X11 only for now)
    warn "Using AppImage install (works for X11; Wayland on non-Debian requires manual compile)"
    mkdir -p ~/opt
    wget -q -O ~/opt/Espanso.AppImage \
      'https://github.com/espanso/espanso/releases/latest/download/Espanso-X11.AppImage'
    chmod u+x ~/opt/Espanso.AppImage
    sudo ~/opt/Espanso.AppImage env-path register
  fi

  info "Registering Espanso as a systemd service..."
  espanso service register
  espanso start
  success "Espanso installed and started"
}

setup_config() {
  info "Setting up Espanso config..."

  if [[ "$OS" == "mac" ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/espanso"
  else
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/espanso"
  fi

  mkdir -p "$CONFIG_DIR/match" "$CONFIG_DIR/config"

  # Copy our match file
  cp "$REPO_DIR/config/match/base.yml" "$CONFIG_DIR/match/base.yml"

  # Copy default config if not already present
  if [ ! -f "$CONFIG_DIR/config/default.yml" ]; then
    cp "$REPO_DIR/config/config/default.yml" "$CONFIG_DIR/config/default.yml"
  fi

  success "Config copied to: $CONFIG_DIR"
}

setup_env() {
  info "Setting up .env file..."
  ENV_FILE="$REPO_DIR/.env"
  EXAMPLE_FILE="$REPO_DIR/.env.example"

  if [ ! -f "$ENV_FILE" ]; then
    cp "$EXAMPLE_FILE" "$ENV_FILE"
    warn "Created .env from .env.example — please fill in your API keys:"
    warn "  nano $ENV_FILE"
  else
    info ".env already exists, skipping."
  fi
}

install_deps() {
  info "Checking dependencies..."
  local missing=()

  command -v curl  &>/dev/null || missing+=("curl")
  command -v wget  &>/dev/null || missing+=("wget")
  command -v jq    &>/dev/null || missing+=("jq")
  command -v xclip &>/dev/null && CLIPBOARD_CMD="xclip" || true
  command -v xsel  &>/dev/null && CLIPBOARD_CMD="xsel"  || true
  command -v wl-copy &>/dev/null && CLIPBOARD_CMD="wl-copy" || true

  if [[ "$OS" == "linux" ]] && [ -z "${CLIPBOARD_CMD:-}" ]; then
    if [[ "$SESSION" == "wayland" ]]; then
      missing+=("wl-clipboard")
    else
      missing+=("xclip")
    fi
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    info "Installing missing dependencies: ${missing[*]}"
    if [[ "$OS" == "mac" ]]; then
      brew install "${missing[@]}"
    elif [[ "$DISTRO" == "debian" ]]; then
      sudo apt install -y "${missing[@]}"
    elif [[ "$DISTRO" == "fedora" ]]; then
      sudo dnf install -y "${missing[@]}"
    elif [[ "$DISTRO" == "arch" ]]; then
      sudo pacman -S --noconfirm "${missing[@]}"
    else
      warn "Please manually install: ${missing[*]}"
    fi
  fi
  success "Dependencies OK"
}

make_scripts_executable() {
  info "Making scripts executable..."
  chmod +x "$SCRIPTS_DIR"/*.sh
  success "Scripts are now executable"
}

print_next_steps() {
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  Espanso Utility installed!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Add your API keys:    nano $REPO_DIR/.env"
  echo "  2. Reload environment:   source $REPO_DIR/load-env.sh"
  echo "  3. Restart Espanso:      espanso restart"
  echo "  4. Test it — type :wttt anywhere"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
detect_os

if [[ "$OS" == "mac" ]]; then
  install_espanso_mac
else
  install_espanso_linux
fi

install_deps
setup_env
setup_config
make_scripts_executable
print_next_steps
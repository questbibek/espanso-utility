#!/usr/bin/env bash
# ==============================================================================
# Espanso Utility - Mac & Linux Installer
# Run this once on a fresh machine:
#   bash <(curl -fsSL https://raw.githubusercontent.com/questbibek/espanso-utility/unix/espanso.sh)
# ==============================================================================
set -e

UTILITY_REPO="https://github.com/questbibek/espanso-utility.git"
CONFIG_REPO="https://github.com/questbibek/espanso.git"
UTILITY_BRANCH="unix"
CONFIG_BRANCH="unix"
REPO_DIR="$HOME/espanso-utility"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Detect OS & Display Server ─────────────────────────────────────────────────
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if [ -f /etc/debian_version ]; then
      DISTRO="debian"
    elif [ -f /etc/fedora-release ]; then
      DISTRO="fedora"
    elif [ -f /etc/arch-release ]; then
      DISTRO="arch"
    else
      DISTRO="other"
    fi
    SESSION="${XDG_SESSION_TYPE:-}"
    if [ -z "$SESSION" ]; then
      SESSION=$(loginctl show-session "$(loginctl | grep "$(whoami)" | awk '{print $1}')" -p Type --value 2>/dev/null || echo "x11")
    fi
  else
    error "Unsupported OS: $OSTYPE"
  fi
}

# ── Clone Repos ────────────────────────────────────────────────────────────────
clone_repos() {
  # 1. espanso-utility → ~/espanso-utility
  if [ -d "$REPO_DIR/.git" ]; then
    info "espanso-utility already cloned, pulling latest..."
    cd "$REPO_DIR"
    git fetch origin
    git checkout "$UTILITY_BRANCH"
    git pull origin "$UTILITY_BRANCH"
  else
    info "Cloning espanso-utility ($UTILITY_BRANCH branch)..."
    git clone -b "$UTILITY_BRANCH" "$UTILITY_REPO" "$REPO_DIR"
    success "Cloned to $REPO_DIR"
  fi

  # 2. espanso config → correct config dir
  if [[ "$OS" == "mac" ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/espanso"
  else
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/espanso"
  fi

  if [ -d "$CONFIG_DIR/.git" ]; then
    info "Espanso config already cloned, pulling latest..."
    cd "$CONFIG_DIR"
    git fetch origin
    git checkout "$CONFIG_BRANCH"
    git pull origin "$CONFIG_BRANCH"
  else
    info "Cloning espanso config ($CONFIG_BRANCH branch)..."
    # Stop espanso before touching config dir
    espanso stop 2>/dev/null || true
    # Remove existing config dir if it exists but isn't a git repo
    if [ -d "$CONFIG_DIR" ]; then
      warn "Backing up existing config to ${CONFIG_DIR}.bak"
      mv "$CONFIG_DIR" "${CONFIG_DIR}.bak"
    fi
    git clone -b "$CONFIG_BRANCH" "$CONFIG_REPO" "$CONFIG_DIR"
    success "Cloned espanso config to $CONFIG_DIR"
  fi
}

# ── Install Espanso ────────────────────────────────────────────────────────────
install_espanso() {
  if command -v espanso &>/dev/null; then
    info "Espanso already installed: $(espanso --version)"
    return
  fi

  if [[ "$OS" == "mac" ]]; then
    info "Installing Espanso on macOS..."
    if ! command -v brew &>/dev/null; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install --cask espanso

    info "Setting up Espanso auto-start (launchd)..."
    PLIST_DIR="$HOME/Library/LaunchAgents"
    PLIST_FILE="$PLIST_DIR/com.espanso.espanso.plist"
    mkdir -p "$PLIST_DIR"
    cat > "$PLIST_FILE" <<PLIST
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
PLIST
    launchctl load "$PLIST_FILE"
    success "Espanso installed and auto-start configured"

  else
    info "Installing Espanso on Linux (distro: $DISTRO, display: $SESSION)..."
    if [[ "$DISTRO" == "debian" ]]; then
      if [[ "$SESSION" == "wayland" ]]; then
        DEB_URL="https://github.com/espanso/espanso/releases/latest/download/espanso-debian-wayland-amd64.deb"
      else
        DEB_URL="https://github.com/espanso/espanso/releases/latest/download/espanso-debian-x11-amd64.deb"
      fi
      wget -q -O /tmp/espanso.deb "$DEB_URL"
      sudo apt install -y /tmp/espanso.deb
      rm /tmp/espanso.deb
    else
      warn "Using AppImage install..."
      mkdir -p ~/opt
      wget -q -O ~/opt/Espanso.AppImage \
        'https://github.com/espanso/espanso/releases/latest/download/Espanso-X11.AppImage'
      chmod u+x ~/opt/Espanso.AppImage
      sudo ~/opt/Espanso.AppImage env-path register
    fi

    info "Registering Espanso as systemd service..."
    espanso service register
    espanso start
    success "Espanso installed and started"
  fi
}

# ── Install Dependencies ───────────────────────────────────────────────────────
install_deps() {
  info "Installing dependencies..."

  if [[ "$OS" == "mac" ]]; then
    local deps=(curl wget jq git)
    for dep in "${deps[@]}"; do
      if ! command -v "$dep" &>/dev/null; then
        info "Installing $dep..."
        brew install "$dep"
      else
        info "$dep already installed"
      fi
    done
    success "Mac dependencies ready (osascript built-in, no xdotool needed)"

  else
    local deps=(curl wget jq git)

    if [[ "$SESSION" == "wayland" ]]; then
      deps+=(wl-clipboard)
    else
      deps+=(xclip xdotool)
    fi

    deps+=(libnotify-bin)

    local to_install=()
    for dep in "${deps[@]}"; do
      if ! command -v "$dep" &>/dev/null; then
        to_install+=("$dep")
      else
        info "$dep already installed"
      fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
      info "Installing: ${to_install[*]}"
      if [[ "$DISTRO" == "debian" ]]; then
        sudo apt install -y "${to_install[@]}"
      elif [[ "$DISTRO" == "fedora" ]]; then
        sudo dnf install -y "${to_install[@]}"
      elif [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -S --noconfirm "${to_install[@]}"
      else
        warn "Please manually install: ${to_install[*]}"
      fi
    fi
    success "Linux dependencies ready"
  fi
}

# ── Setup .env ─────────────────────────────────────────────────────────────────
setup_env() {
  info "Setting up .env..."
  ENV_FILE="$REPO_DIR/.env"
  EXAMPLE_FILE="$REPO_DIR/env.example"

  if [ ! -f "$ENV_FILE" ]; then
    cp "$EXAMPLE_FILE" "$ENV_FILE"
    warn ".env created — add your API keys: code $ENV_FILE"
  else
    info ".env already exists, skipping"
  fi
}

# ── Make Scripts Executable ────────────────────────────────────────────────────
make_executable() {
  info "Making scripts executable..."
  chmod +x "$REPO_DIR"/*.sh
  success "All scripts are executable"
}

# ── Load Env into Shell ────────────────────────────────────────────────────────
setup_shell_env() {
  info "Adding load-env.sh to shell rc files..."
  LOAD_CMD="source $REPO_DIR/load-env.sh"

  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
      if ! grep -q "espanso-utility/load-env.sh" "$rc_file"; then
        echo "$LOAD_CMD" >> "$rc_file"
        success "Added to $rc_file"
      else
        info "Already in $rc_file"
      fi
    fi
  done
}

# ── Restart Espanso ────────────────────────────────────────────────────────────
restart_espanso() {
  info "Restarting Espanso..."
  espanso restart 2>/dev/null || espanso start
  success "Espanso restarted"
}

# ── Print Summary ──────────────────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  Espanso Utility installed!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "  OS:       $OS ${DISTRO:-}"
  echo "  Repo:     $REPO_DIR"
  echo ""
  echo "  Next steps:"
  echo "  1. Add API keys:     code $REPO_DIR/.env"
  echo "  2. Load env now:     source $REPO_DIR/load-env.sh"
  echo "  3. Test:             type :wttt anywhere"
  echo ""
  echo "  One-line install for next machine:"
  echo "  bash <(curl -fsSL https://raw.githubusercontent.com/questbibek/espanso-utility/unix/espanso.sh)"
  echo ""
}

# ── Main ───────────────────────────────────────────────────────────────────────
detect_os
install_deps
install_espanso
clone_repos
setup_env
make_executable
setup_shell_env
restart_espanso
print_summary

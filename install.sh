#!/bin/bash
set -e

LEGENDARY_ZSH_HOME="${HOME}/.local/share/legendary-zsh"

# --- Dependency installation ---

install_deps() {
  local missing=()

  for cmd in git zsh fzf starship zoxide eza; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done

  if [ ${#missing[@]} -eq 0 ]; then
    echo "All dependencies already installed."
    return
  fi

  echo "Missing: ${missing[*]}"

  if [[ "$OSTYPE" == darwin* ]]; then
    if ! command -v brew &>/dev/null; then
      echo "Error: Homebrew is required on macOS. Install it from https://brew.sh"
      exit 1
    fi
    # macOS ships with git and zsh, but handle them just in case
    echo "Installing dependencies via Homebrew..."
    brew install "${missing[@]}"

  elif command -v pacman &>/dev/null; then
    echo "Installing dependencies via pacman..."
    sudo pacman -S --needed --noconfirm "${missing[@]}"

  elif command -v apt-get &>/dev/null; then
    # starship, zoxide, and eza aren't in default apt repos — install those separately
    local apt_pkgs=()
    local manual_pkgs=()

    for pkg in "${missing[@]}"; do
      case "$pkg" in
        starship|zoxide|eza) manual_pkgs+=("$pkg") ;;
        *) apt_pkgs+=("$pkg") ;;
      esac
    done

    if [ ${#apt_pkgs[@]} -gt 0 ]; then
      echo "Installing ${apt_pkgs[*]} via apt..."
      sudo apt-get update -qq
      sudo apt-get install -y "${apt_pkgs[@]}"
    fi

    for pkg in "${manual_pkgs[@]}"; do
      case "$pkg" in
        starship)
          echo "Installing starship..."
          curl -sS https://starship.rs/install.sh | sh -s -- -y
          ;;
        zoxide)
          echo "Installing zoxide..."
          curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
          ;;
        eza)
          echo "Installing eza..."
          sudo mkdir -p /etc/apt/keyrings
          wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
          echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
          sudo apt-get update -qq
          sudo apt-get install -y eza
          ;;
      esac
    done

  elif command -v dnf &>/dev/null; then
    echo "Installing dependencies via dnf..."
    local dnf_pkgs=()
    local manual_pkgs=()

    for pkg in "${missing[@]}"; do
      case "$pkg" in
        starship) manual_pkgs+=("$pkg") ;;
        *) dnf_pkgs+=("$pkg") ;;
      esac
    done

    if [ ${#dnf_pkgs[@]} -gt 0 ]; then
      sudo dnf install -y "${dnf_pkgs[@]}"
    fi

    for pkg in "${manual_pkgs[@]}"; do
      case "$pkg" in
        starship)
          echo "Installing starship..."
          curl -sS https://starship.rs/install.sh | sh -s -- -y
          ;;
      esac
    done

  else
    echo "Error: Could not detect package manager. Install these manually: ${missing[*]}"
    exit 1
  fi
}

# --- Main ---

if [ -d "$LEGENDARY_ZSH_HOME" ]; then
  echo "Existing installation found. Updating..."
  "$LEGENDARY_ZSH_HOME/bin/legendary-update"
else
  echo "Installing legendary-zsh..."
  install_deps

  git clone https://github.com/jzetterman/legendary-zsh.git "$LEGENDARY_ZSH_HOME"
  "$LEGENDARY_ZSH_HOME/bin/legendary-setup-zsh"
fi

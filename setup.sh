#!/usr/bin/env bash

set -euo pipefail

# ============================================================================ #
# Constants and Configuration
# ============================================================================ #



# ============================================================================ #
# Utility Functions
# ============================================================================ #

log() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

# ============================================================================ #
# Package Management Functions
# ============================================================================ #

install_ansible_macos() {
  if ! command -v brew >/dev/null; then
    error "❌ Homebrew not found. Please install it from https://brew.sh"
    exit 1
  fi

  if ! command -v ansible >/dev/null; then
    log "Installing Ansible via Homebrew..."
    brew install ansible
  fi
}

install_ansible_ubuntu() {
  if ! command -v ansible >/dev/null; then
    log "Installing Ansible via apt..."
    sudo apt update -y
    sudo apt install -y ansible
  fi
}

detect_os_and_install_ansible() {
  case "$(uname -s)" in
  Darwin)
    log "Detected macOS"
    install_ansible_macos
    ;;
  Linux)
    log "Detected Linux"
    install_ansible_ubuntu
    ;;
  *)
    error "Unsupported OS: $(uname -s)"
    exit 1
    ;;
  esac
}

# ============================================================================ #
# Core Setup Functions
# ============================================================================ #

generate_ssh_key() {
  if [[ ! -f ~/.ssh/personal_id_ed25519 ]]; then
    mkdir -p ~/.ssh
    echo -n "GitHub email: "
    read email
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/personal_id_ed25519 -N ""
    cat ~/.ssh/personal_id_ed25519.pub | xclip -selection clipboard
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/personal_id_ed25519

    log "SSH key generated and copied to clipboard"
    log "Please add the key to GitHub and press enter to continue"
    read -p "Press enter to continue"
  fi
}

# ============================================================================ #
# Tool Installation Functions
# ============================================================================ #

run_ansible_and_continue() {
  if command -v ansible >/dev/null; then
    log "Running Ansible playbook..."
    ansible-playbook -i ~/dotfiles/ansible/inventory.ini ~/dotfiles/ansible/setup.yml
  fi
}

# ============================================================================ #
# Main Script Logic
# ============================================================================ #

main() {
  # Check for enhanced getopt
  if ! getopt --test >/dev/null 2>&1; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install gnu-getopt
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      sudo apt install util-linux
    else
      error "Unsupported OS: $OSTYPE" >&2
      exit 1
    fi
  fi

  generate_ssh_key
  detect_os_and_install_ansible
  run_ansible_and_continue
  source ~/.zshrc

  log "✅ Full bootstrap complete!"
}

main "$@"


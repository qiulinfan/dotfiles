#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
GIT_SSH_EMAIL="rynnefan@umich.edu"
INSTALL_APT=false
INSTALL_NVIM=false
INSTALL_EDITOR_DEPS=false
INSTALL_BLOG_DEPS=false
INSTALL_NERD_FONT=false
SETUP_SSH_KEY=false
SET_DEFAULT_FISH=false
LINK_ONLY=true

usage() {
  cat <<'EOF'
Usage: ./initial.sh [options]

By default, this script only links dotfiles into the expected locations.
Installation steps are opt-in because they use sudo, download binaries, create SSH keys, or change the login shell.

Options:
  --install-apt         Install common Ubuntu/WSL packages with apt.
  --install-nvim       Install latest Neovim release to /opt and /usr/local/bin/nvim.
  --install-editor-deps Install Vim/Neovim dependencies: vim-plug, Node.js, tree-sitter, lazygit, bottom.
  --install-vim-deps   Alias for --install-editor-deps.
  --install-blog-deps  Install qlblog dependencies: Node.js 20, Corepack, pnpm 9.14.4, make.
  --install-fonts      Install JetBrainsMono Nerd Font for AstroNvim icons.
  --ssh-key            Create an ed25519 GitHub SSH key if it does not exist.
  --set-fish-shell     Add fish to /etc/shells and set it as the default login shell.
  --all                Run all installation steps, then link dotfiles.
  -h, --help           Show this help.

Examples:
  ./initial.sh
  ./initial.sh --install-apt --install-nvim --install-editor-deps
  ./initial.sh --install-blog-deps
  ./initial.sh --all
EOF
}

for arg in "$@"; do
  case "$arg" in
    --install-apt)
      INSTALL_APT=true
      ;;
    --install-nvim)
      INSTALL_NVIM=true
      ;;
    --install-editor-deps|--install-vim-deps)
      INSTALL_EDITOR_DEPS=true
      ;;
    --install-blog-deps)
      INSTALL_BLOG_DEPS=true
      ;;
    --install-fonts)
      INSTALL_NERD_FONT=true
      ;;
    --ssh-key)
      SETUP_SSH_KEY=true
      ;;
    --set-fish-shell)
      SET_DEFAULT_FISH=true
      ;;
    --all)
      INSTALL_APT=true
      INSTALL_NVIM=true
      INSTALL_EDITOR_DEPS=true
      INSTALL_BLOG_DEPS=true
      INSTALL_NERD_FONT=true
      SETUP_SSH_KEY=true
      SET_DEFAULT_FISH=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage
      exit 1
      ;;
  esac
  LINK_ONLY=false
done

need_cmd() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
}

apt_install_if_available() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get not found; skipping Ubuntu package installation."
    return
  fi

  echo "Installing Ubuntu/WSL packages..."
  sudo apt-get update

  if command -v add-apt-repository >/dev/null 2>&1; then
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
    sudo apt-get update
  else
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
    sudo apt-get update
  fi

  sudo apt-get install -y \
    build-essential \
    curl \
    fish \
    fzf \
    g++-13 \
    gcc-13 \
    gdb \
    git \
    make \
    openssh-client \
    python3 \
    ripgrep \
    rsync \
    snapd \
    tree \
    unzip \
    vim \
    wget \
    wl-clipboard \
    xclip \
    xsel

  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100
  sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100
}

install_neovim() {
  need_cmd curl
  need_cmd tar

  echo "Installing latest Neovim release..."
  local archive="/tmp/nvim-linux-x86_64.tar.gz"
  local extracted="/tmp/nvim-linux-x86_64"

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get remove -y neovim neovim-runtime || true
  fi

  rm -rf "$archive" "$extracted"
  curl -fL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" -o "$archive"
  tar xzf "$archive" -C /tmp

  sudo rm -rf /opt/nvim-linux-x86_64
  sudo mv "$extracted" /opt/nvim-linux-x86_64
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm -f "$archive"

  echo "Neovim installed: $(command -v nvim)"
  nvim --version | head -n 1
  nvim --headless --clean +'lua print(vim.env.VIMRUNTIME)' +qa
  echo
}

install_nodejs_20() {
  need_cmd curl

  if command -v apt-get >/dev/null 2>&1; then
    if command -v node >/dev/null 2>&1 && [[ "$(node --version)" == v20.* ]] && command -v npm >/dev/null 2>&1; then
      echo "Node.js 20 and npm are already installed."
    else
      echo "Installing Node.js 20 from NodeSource..."
      sudo apt-get remove -y libnode-dev libnode72 nodejs || true
      curl -fsSL "https://deb.nodesource.com/setup_20.x" | sudo -E bash -
      sudo apt-get install -y nodejs
    fi
  elif ! command -v node >/dev/null 2>&1 || [[ "$(node --version)" != v20.* ]] || ! command -v npm >/dev/null 2>&1; then
    echo "Node.js 20 and npm are required; automatic installation currently supports apt-based systems." >&2
    exit 1
  fi
}

install_editor_dependencies() {
  need_cmd curl

  echo "Installing vim-plug..."
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

  install_nodejs_20

  if command -v npm >/dev/null 2>&1; then
    sudo npm install -g yarn tree-sitter-cli@0.22.6
  else
    echo "npm not found; skipping yarn and tree-sitter-cli installation."
  fi

  if command -v snap >/dev/null 2>&1; then
    sudo snap install lazygit || true
    sudo snap install bottom || true

    if [[ -x /snap/bin/bottom ]]; then
      sudo rm -f /usr/local/bin/btm
      printf '%s\n' '#!/usr/bin/env sh' 'exec /snap/bin/bottom "$@"' | sudo tee /usr/local/bin/btm >/dev/null
      sudo chmod +x /usr/local/bin/btm
    fi
  else
    echo "snap not found; skipping lazygit and bottom installation."
  fi
}

install_blog_dependencies() {
  install_nodejs_20
  need_cmd npm

  if command -v apt-get >/dev/null 2>&1 && ! command -v make >/dev/null 2>&1; then
    echo "Installing GNU Make..."
    sudo apt-get update
    sudo apt-get install -y make
  fi
  need_cmd make

  if ! command -v corepack >/dev/null 2>&1; then
    echo "Installing Corepack..."
    sudo npm install -g corepack@0.34.6
  fi

  echo "Enabling Corepack and preparing pnpm 9.14.4..."
  sudo corepack enable
  corepack pnpm@9.14.4 --version

  echo "qlblog dependencies are ready:"
  echo "  $(node --version)"
  echo "  npm $(npm --version)"
  echo "  pnpm $(corepack pnpm@9.14.4 --version)"
  echo "  $(make --version | head -n 1)"
}

install_nerd_font() {
  need_cmd curl
  need_cmd unzip

  echo "Installing JetBrainsMono Nerd Font..."
  local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  local archive="/tmp/JetBrainsMono.zip"

  mkdir -p "$font_dir"
  curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$archive"
  unzip -o "$archive" -d "$font_dir" >/dev/null
  rm -f "$archive"

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir"
  fi

  find "$font_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) | wc -l
}

setup_ssh_key() {
  need_cmd ssh-keygen

  local key_path="$HOME/.ssh/id_ed25519"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [[ -f "$key_path" ]]; then
    echo "SSH key already exists: $key_path"
  else
    echo "Creating SSH key: $key_path"
    ssh-keygen -t ed25519 -C "$GIT_SSH_EMAIL" -f "$key_path"
  fi

  echo "Public key for GitHub:"
  cat "$key_path.pub"
}

set_default_fish_shell() {
  need_cmd fish
  need_cmd chsh

  local fish_path
  fish_path="$(command -v fish)"

  local target_user
  target_user="${SUDO_USER:-${USER:-}}"

  if [[ -z "$target_user" ]]; then
    target_user="$(id -un)"
  fi

  if [[ ! -f /etc/shells ]]; then
    echo "/etc/shells not found; cannot set fish as a login shell." >&2
    exit 1
  fi

  if grep -Fxq "$fish_path" /etc/shells; then
    echo "fish is already listed in /etc/shells: $fish_path"
  else
    echo "Adding fish to /etc/shells: $fish_path"
    printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  local current_shell
  current_shell="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f7 || true)"

  if [[ -z "$current_shell" && -r /etc/passwd ]]; then
    current_shell="$(awk -F: -v user="$target_user" '$1 == user { print $7 }' /etc/passwd)"
  fi

  if [[ "$current_shell" == "$fish_path" ]]; then
    echo "Default shell is already fish: $fish_path"
    return
  fi

  echo "Setting default shell for $target_user to $fish_path"
  sudo chsh -s "$fish_path" "$target_user"
  echo "Open a new terminal session for the default shell change to take effect."
}

backup_path() {
  local target="$1"
  local backup="$target.bak.$(date +%Y%m%d%H%M%S)"

  echo "Backing up existing $target to $backup"
  mv "$target" "$backup"
}

link_path() {
  local source="$1"
  local target="$2"
  local label="$3"

  if [[ ! -e "$source" ]]; then
    echo "Skip $label: source does not exist: $source"
    return
  fi

  if [[ -L "$target" ]]; then
    local current_target
    current_target="$(readlink "$target")"

    if [[ "$current_target" == "$source" ]]; then
      echo "Already linked: $target -> $source"
      return
    fi

    echo "Removing existing symlink: $target -> $current_target"
    rm "$target"
  elif [[ -e "$target" ]]; then
    backup_path "$target"
  fi

  echo "Linking $target -> $source"
  ln -s "$source" "$target"
}

link_config() {
  local name="$1"
  link_path "$DOTFILES_DIR/$name" "$CONFIG_DIR/$name" "$name"
}

link_home_file() {
  local source="$1"
  local target="$2"
  link_path "$source" "$target" "$(basename "$target")"
}

link_dotfiles() {
  mkdir -p "$CONFIG_DIR"

  link_config fish
  link_config nvim
  link_home_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
  link_home_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
}

$INSTALL_APT && apt_install_if_available
$INSTALL_NVIM && install_neovim
$INSTALL_EDITOR_DEPS && install_editor_dependencies
$INSTALL_BLOG_DEPS && install_blog_dependencies
$INSTALL_NERD_FONT && install_nerd_font
$SETUP_SSH_KEY && setup_ssh_key
$SET_DEFAULT_FISH && set_default_fish_shell

link_dotfiles

echo "Done."

if $LINK_ONLY; then
  echo "Tip: run './initial.sh --help' to see optional installers."
fi

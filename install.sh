#!/data/data/com.termux/files/usr/bin/bash
# Install script for My Termux Dotfiles
# Set custom variables
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
ENDCOLOR=$'\e[0m'

function error_exit {
  echo -e "${RED}Error: $1${ENDCOLOR}" >&2
  exit 1
}

# Set Up Storage
termux-setup-storage

# Update Packages
echo "--- Install termux repo for python3.9"
pkg install tur-repo
apt update && yes | apt upgrade || error_exit "${RED}Failed to update packages.${ENDCOLOR}"
apt update && apt install gh git-lfs zsh openssh -y

# Set up GitHub auth
gh auth login || error_exit "${RED}Failed to set up GitHub auth.${ENDCOLOR}"

# Set Up Git Credentials
echo -e "${YELLOW}Time to set up your Git credentials!${ENDCOLOR}"

# Prompt the user for their Git username
read -rp "${GREEN}Enter your Git username${ENDCOLOR}: " username

# Prompt the user for their Git email
read -rp "${GREEN}Enter your Git email${ENDCOLOR}: " email

# Prompt the user to choose between global and system-wide configuration
read -rp "${GREEN}Would you like to set your Git configuration system-wide? (Yes/No)${ENDCOLOR}: " choice

# Set Up SSH Key
if [ ! -f ~/.ssh/id_ed25519 ]; then
  # Generate an Ed25519 SSH key pair
  HOME=/data/data/com.termux/files/home ssh-keygen -t ed25519 -C "$email"
  # Check if an SSH key pair already exists
  eval "$(ssh-agent -s)"
  HOME=/data/data/com.termux/files/home ssh-add ~/.ssh/id_ed25519
fi

# Create file containing SSH public key for verifying signers
awk '{ print $3 " " $1 " " $2 }' ~/.ssh/id_ed25519.pub >> ~/.ssh/allowed_signers

if [[ "$choice" == [Yy]* ]]; then
  # Set the Git username and email system-wide
  git config --system user.name "$username"
  git config --system user.email "$email"
  git config --system gpg.format ssh
  git config --system user.signingkey ~/.ssh/id_ed25519.pub
  git config --system gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
  git config --system merge.verifySignatures true
  git config --system log.showSignature true
  git config --system commit.gpgsign true
  git config --system tag.gpgsign true
  git config --system push.autoSetupRemote true
  git config --system fetch.prune true
  git config --system core.editor nvim
  git config --system core.autocrlf input
  git config --system init.defaultBranch main
  git config --system color.status auto
  git config --system color.branch auto
  git config --system color.interactive auto
  git config --system color.diff auto
  git config --system status.short true
  git config --system alias.assume-unchanged 'update-index --assume-unchanged'
  git config --system alias.assume-changed 'update-index --no-assume-unchanged'
  # Transfer gh helper config to system config
  cat "$HOME/.gitconfig" >> "/data/data/com.termux/files/usr/etc/gitconfig"
  # Clean up unnecessary file
  rm "$HOME/.gitconfig"
  # Provide Pubkey for gpgsigning
  echo "${YELLOW}COPY THE FOLLOWING OUTPUT${ENDCOLOR}"
  echo "${GREEN}Your public key (id_ed25519.pub) is${ENDCOLOR}:"
  cat ~/.ssh/id_ed25519.pub
  echo "${YELLOW}Make sure to add your public key to your Git hosting provider${ENDCOLOR}!"
  sleep 25
  echo -e "${GREEN}Git credentials configured system-wide.${ENDCOLOR}"
else
  # Set the Git username and email globally
  git config --global user.name "$username"
  git config --global user.email "$email"
  git config --global gpg.format ssh
  git config --global user.signingkey ~/.ssh/id_ed25519.pub
  git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
  git config --global merge.verifySignatures true
  git config --global log.showSignature true
  git config --global commit.gpgsign true
  git config --global tag.gpgsign true
  git config --global push.autoSetupRerun true
  git config --global fetch.prune true
  git config --global core.editor nvim
  git config --global core.autocrlf input
  git config --global init.defaultBranch main
  git config --global color.status auto
  git config --global color.branch auto
  git config --global color.interactive auto
  git config --global color.diff auto
  git config --global status.short true
  git config --global alias.assume-unchanged 'update-index --assume-unchanged'
  git config --global alias.assume-changed 'update-index --no-assume-unchanged'
  # Provide Pubkey for gpgsigning
  echo "${YELLOW}COPY THE FOLLOWING OUTPUT${ENDCOLOR}"
  echo "${YELLOW}Your public key (id_ed25519.pub) is${ENDCOLOR}:"
  cat ~/.ssh/id_ed25519.pub
  echo "${YELLOW}Make sure to add your public key to your Git hosting provider${ENDCOLOR}!"
  sleep 25
  echo -e "${GREEN}Git credentials configured globally.${ENDCOLOR}"
fi

# Install MOTD
echo "${GREEN}Installing MOTD${ENDCOLOR}"
sleep 2
rm /data/data/com.termux/files/usr/etc/motd
git clone https://github.com/GR3YH4TT3R93/termux-motd.git /data/data/com.termux/files/usr/etc/motd
echo "/data/data/com.termux/files/usr/etc/motd/init.sh" >> /data/data/com.termux/files/usr/etc/zprofile

# Install Oh My Zsh
echo "${GREEN}Installing Oh-My-Zsh${ENDCOLOR}"
sleep 2
sh -c "$(curl -fsSL https://raw.githubusercontent.com/GR3YH4TT3R93/ohmyzsh/master/tools/install.sh)"

# Clean up excess files
rm ".shell.pre-oh-my-zsh"

# Install Powerlevel10k
echo -e "${GREEN}Installing Powerlevel10k${ENDCOLOR}"
sleep 2
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" || error_exit "${RED}Failed to install Powerlevel10k.${ENDCOLOR}"

# Install Oh My Zsh plugins
echo -e "${GREEN}Time to choose your Zsh plugins!${ENDCOLOR}"
sleep 2
# Ask if user wants to install zsh plugins

# Auto-Suggestions
read -rp "${YELLOW}Would You Like Auto-Suggestions? (Yes/No)${ENDCOLOR}: " suggestions

if [[ "$suggestions" == [Yy]* ]]; then
  echo -e "${GREEN}Installing Zsh Auto-Suggestions${ENDCOLOR}"
  sleep 1
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || error_exit "${RED}Failed to install zsh-autosuggestions.${ENDCOLOR}"
else
  echo "${RED}Skipping${ENDCOLOR}"
  sed -i '/zsh-autosuggestions/d' ~/.zshrc
fi

# Completions
read -rp "${YELLOW}How about completions? (Yes/No)${ENDCOLOR}: " completions

if [[ "$completions" == [Yy]* ]]; then
  echo -e "${GREEN}Installing Zsh Completions${ENDCOLOR}"
  sleep 1
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions" || error_exit "${RED}Failed to install zsh-completions.${ENDCOLOR}"
else
  echo "${RED}Skipping${ENDCOLOR}"
  sed -i '/zsh-completions/d' ~/.zshrc
fi

# History Substring Search
read -rp "${YELLOW}History Substring Search? (Yes/No)${ENDCOLOR}: " substring

if [[ "$substring" == [Yy]* ]]; then
  echo -e "${GREEN}Installing History Substring Search${ENDCOLOR}"
  sleep 1
  git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search" || error_exit "${RED}Failed to install zsh-history-substring-search.${ENDCOLOR}"
else
  echo "${RED}Skipping${ENDCOLOR}"
  sed -i '/zsh-history-substring-search/d' ~/.zshrc
fi

# Syntax Highlighting
read -rp "${YELLOW}Syntax Highlighting? (Yes/No)${ENDCOLOR}: " highlighting
if [[ "$highlighting" == [Yy]* ]]; then
  echo -e "${GREEN}Installing Syntax Highlighting${ENDCOLOR}"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || error_exit "${RED}Failed to install zsh-syntax-highlighting.${ENDCOLOR}"
else
  echo "${RED}Skipping${ENDCOLOR}"
  sed -i '/zsh-syntax-highlighting/d' ~/.zshrc
fi

read -rp "${YELLOW}Git Flow Completions? (Yes/No)${ENDCOLOR}: " git
# Git Flow Completions
if [[ "$git" == [Yy]* ]]; then
  echo -e "${GREEN}Installing Git Flow Completions${ENDCOLOR}"
  sleep 1
  git clone https://github.com/bobthecow/git-flow-completion "$ZSH_CUSTOM/plugins/git-flow-completion" || error_exit "${RED}Failed to install git-flow-completion.${ENDCOLOR}"
else
  echo "${RED}Skipping${ENDCOLOR}"
  sed -i '/git-flow-completion/d' ~/.zshrc
fi

# Zsh Vi Mode
read -rp "${YELLOW}Zsh Vi Mode? (Yes/No)${ENDCOLOR}: " vi
if [[ "$vi" == [Yy]* ]]; then
  echo -e "${GREEN}Installing Zsh Vi Mode${ENDCOLOR}"
  sleep 1
  git clone https://github.com/jeffreytse/zsh-vi-mode "$ZSH_CUSTOM/plugins/zsh-vi-mode" || error_exit "${RED}Failed to install zsh-vi-mode.${ENDCOLOR}"
else
  echo "${RED}Skipping${ENDCOLOR}"
  sed -i '/zsh-vi-mode/d' ~/.zshrc
  sed -i '/^function zvm_config() {/,/^}$/d' ~/.zshrc
fi

# Magic Enter
read -rp "${YELLOW}Magic Enter? (Yes/No)${ENDCOLOR}: " magic
if [[ "$magic" == [Yy]* ]]; then
  echo -e "${GREEN}Installing Magic-Enter${ENDCOLOR}"
  sleep 1
  git clone https://github.com/GR3YH4TT3R93/magic-enter "$ZSH_CUSTOM/plugins/magic-enter" || error_exit "${RED}Failed to install magic-enter.${ENDCOLOR}"
else
  echo "${RED}Skipping${ENDCOLOR}"
  sed -i '/magic-enter/d' ~/.zshrc
fi

# Make sure user wants Neovim config
read -rp "${YELLOW}Would you like to keep the included Neovim Config? (Yes/No)${ENDCOLOR}: " neovim

if [[ "$neovim" == [Nn]* ]]; then
  echo "${RED}Removing Neovim Config!${ENDCOLOR}"
  echo "${YELLOW}You will now need to configure neovim yourself!${ENDCOLOR}"
  rm -rf ~/.config/nvim ~/.local/share/nvim/
fi

echo "Clone .dotfiles ~/.dotfiles"
git clone https://github.com/julianobarbosa/.dotfiles.git ~

echo "Clone neovim-ide into ~/.config/nvim"
git clone https://github.com/julianobarbosa/neovim-ide.git ~/.config/nvim

# Hide README.md
file_path="$HOME/GitHub/dotfiles"

# Check if the file exists and is readable
if [ -e "$file_path" ]; then
  if [ -r "$file_path" ]; then
    echo "${YELLOW}Hiding README.md in ~/.termux ${ENDCOLOR}"
    echo "${GREEN}moving...${ENDCOLOR}"
    mv README.md ~/.termux/README.md || error_exit "${RED}Failed to hide README.md.${ENDCOLOR}"
    git --git-dir="$HOME/GitHub/dotfiles" --work-tree="$HOME" --assume-unchanged README.md || error_exit "${RED}Failed to hide README.md.${ENDCOLOR}"
  else
    echo "${RED}File exists but is not readable. Cannot execute Git command.${ENDCOLOR}"
  fi
else
  echo "${YELLOW}Deletinging README.md and .git folder ${ENDCOLOR}"
  echo "${GREEN}Removing...${ENDCOLOR}"
  rm -rf README.md .git || error_exit "${RED}Failed to hide README.md.${ENDCOLOR}"
fi

echo -e "${GREEN}Time to install Nala Package Manager, Termux Clipboard, Neovim, NodeJS, Python-pip, Ruby, LuaRocks, LuaJIT, LazyGit, wget, gettext, logo-ls, ncurses-utils, libuv, Timewarrior, Taskwarrior, and htop!${ENDCOLOR}"
sleep 5

# Install Nala Package Manager, Z Shell, Termux Clipboard, Git, GitHub CLI, Neovim, NodeJS, Python-pip, Ruby, wget, logo-ls, Timewarrior, Taskwarrior, htop
apt update && apt install nala -y
nala install autoconf asciinema binutils build-essential cmake ctags libzmq termux-api gh atuin electrum kubectl k9s which neovim nodejs ninja python-tkinter python-greenlet python-cryptography matplotlib opencv-python python-torch python-pillow python-numpy python-pip ruby golang rclone rust luarocks luajit ripgrep fd lazygit wget gettext logo-ls ncurses-utils libuv stow  libxml2  libxslt timewarrior taskwarrior htop -y || error_exit "${RED}Failed to install packages.${ENDCOLOR}"

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# Install pynvim, pnpm and neovim npm package, and neovim gem package
pip install pynvim || error_exit "${RED}Failed to install pynvim.${ENDCOLOR}"
npm install -g pnpm neovim || error_exit "${RED}Failed to install neovim npm package.${ENDCOLOR}"
gem install neovim || error_exit "${RED}Failed to install neovim gem package.${ENDCOLOR}"
gem update --system || error_exit "${RED}Failed to update gem.${ENDCOLOR}"
luarocks install mpack || error_exit "${RED}Failed to install mpack${ENDCOLOR}"
luarocks install lpeg || error_exit "${RED}Failed to install lpeg.${ENDCOLOR}"

# Finish Setup
echo -e "${GREEN}Setup Complete! Press Ctrl+D for changes to take effect.${ENDCOLOR}"

# python virtualenvs
mkdir -p ~/.virtualenvs
cd ~/.virtualenvs

# tools3
echo "--- Install Virtual env for: tools3"
python -m venv tools3
source ~/.virtualenvs/tools3/bin/activate
python -m pip install -U pip setuptools wheel
python -m pip install -U ansible ansible-lint autoenv autopep8 black codespell colorama cookiecutter fast.com flake8 gnucash-to-beancount isort jedi-language-server jrnl mps-youtube molecule mypy pre-commit prospector pyarmor pydocstyle pyflakes pylama pylint pyls rows speedtest-cli reorder-python-imports thefuck zabbix-api youtube-dl tmuxp vulture yapf yamlfix yamllint visidata virtualenv virtualenvwrapper

# azure-cli
echo "--- Install Virtual env for: azure-cli"
python -m venv azure-cli
source ~/.virtualenvs/azure-cli/bin/activate
python -m pip install -U pip setuptools wheel
python -m pip install -U azure-cli

echo "--- Install direnv ---"
curl -sfL https://direnv.net/install.sh | bash

echo "--- atuin login ---"
atuin login -u barbosa

echo "--- Install coreutils ---"
cargo install coreutils --locked || error_exit "${RED}Failed to update packages.${ENDCOLOR}"

echo "--- Install cargo-binutils ---"
cargo install cargo-binutils --locked || error_exit "${RED}Failed to update packages.${ENDCOLOR}"

echo "--- Install tree-sitter-cli ---"
cargo install tree-sitter-cli --git https://github.com/tree-sitter/tree-sitter.git --tag v0.18.3 || error_exit "${RED}Failed to update packages.${ENDCOLOR}"

echo "--- Install cargo-make ---"
cargo install cargo-make --locked || error_exit "${RED}Failed to update packages.${ENDCOLOR}"

echo "--- Install rust_fzf ---"
cargo add rust_fzf --locked || error_exit "${RED}Failed to update packages.${ENDCOLOR}"

echo "--- Install git-delta ---"
cargo install git-delta --locked || error_exit "${RED}Failed to update packages.${ENDCOLOR}"

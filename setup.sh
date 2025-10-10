#!/usr/bin/env bash

# dotfilesの一部として管理されているカスタムスクリプトを、
# システム全体で使えるコマンドとしてセットアップするスクリプト

DOTFILES_DIR="$HOME/dotfiles"
LOCAL_BIN="$HOME/.local/bin"

# ~/.local/bin ディレクトリを作成
mkdir -p "$LOCAL_BIN"

# .binディレクトリ内のすべてのスクリプトをリンク
for script in "$DOTFILES_DIR/.bin"/*; do
  if [[ -f "$script" ]]; then
    script_name=$(basename "$script")
    ln -sf "$script" "$LOCAL_BIN/$script_name"
    chmod +x "$LOCAL_BIN/$script_name"
    echo "Linked: $script_name"
  fi
done

echo "Setup completed!"
echo -e "Run: \e[1;36m source ~/.bashrc \e[m (or restart your shell)"
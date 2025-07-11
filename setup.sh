#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
LOCAL_BIN="$HOME/.local/bin"

# ~/.local/bin ディレクトリを作成
mkdir -p "$LOCAL_BIN"

# binディレクトリ内のすべてのスクリプトをリンク
for script in "$DOTFILES_DIR/.bin"/*; do
    if [[ -f "$script" ]]; then
        script_name=$(basename "$script")
        ln -sf "$script" "$LOCAL_BIN/$script_name"
        chmod +x "$LOCAL_BIN/$script_name"
        echo "Linked: $script_name"
    fi
done

# PATHの設定
add_to_path() {
    local shell_rc="$1"
    if [[ -f "$shell_rc" ]] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$shell_rc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
        echo "Added PATH to $shell_rc"
    fi
}

add_to_path ~/.bashrc
add_to_path ~/.zshrc

echo "Setup completed!"
echo -e "Run: \e[1;36m source ~/.bashrc \e[m (or restart your shell)"
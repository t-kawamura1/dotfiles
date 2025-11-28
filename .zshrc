# ~/.zshrc

# 共通エイリアスファイルを読み込み
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

# PATH重複チェック関数
add_to_path_once() {
    if [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

# PATH重複を除去する関数
clean_path() {
    export PATH=$(echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')
}

# PATH に ~/.local/bin を追加（重複チェック付き）
add_to_path_once "$HOME/.local/bin"

# Zsh固有の設定
autoload -Uz compinit
compinit

# 履歴設定
HISTSIZE=1000
SAVEHIST=2000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# 補完設定
setopt AUTO_MENU
setopt AUTO_LIST
setopt AUTO_PARAM_SLASH
setopt MARK_DIRS

# ディレクトリ設定
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# カラー設定
autoload -Uz colors && colors

# プロンプトのカスタマイズ
setopt PROMPT_SUBST
PROMPT='%{$fg[green]%}%n%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}$ '
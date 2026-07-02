# !/usr/bin/env bash

# エラーを検出し、スクリプトの実行を停止する
set -ueo pipefail

# dirname "${BASH_SOURCE[0]}" はスクリプトのパスからディレクトリ部分を取得し、
# cd コマンドでそのディレクトリに移動し、pwd -P で絶対パスを取得
# pwd -P はシンボリックリンクを解決して実際のパスを取得するため、
# スクリプトがどのディレクトリから実行されても正しいパスを取得できる
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

helpmsg() {
  # $0 このスクリプト名を表す変数
  # >&2 標準入力を標準エラー出力へリダイレクト
  command echo "Usage: $0 [--help | -h]" >&2
  command echo ""
}

link_to_homedir() {
  command echo "backup old dotfiles..."
  # バックアップディレクトリが存在しない場合は作成
  if [ ! -d "$HOME/.dotbackup" ];then
    command echo "$HOME/.dotbackup not found. Auto Make it"
    command mkdir "$HOME/.dotbackup"
  fi

  # SCRIPT_DIR がホームディレクトリと異なる場合のみ、シンボリックリンクを作成
  # これは同じディレクトリ内でシンボリックリンクを作成してしまう事故を防ぐため
  if [[ "$HOME" != "$SCRIPT_DIR" ]];then
    # /.??* ドットで始まる（ドットを含めた）3文字以上のファイル・ディレクトリ名にマッチ
    for item in $SCRIPT_DIR/.??*; do
      # .git と .config はスキップ（.configは後で個別処理）、.claude はスキップ（link_claude_filesで個別処理）、.local はスキップ（link_local_binで個別処理）
      [[ `basename $item` == ".git" ]] && continue
      [[ `basename $item` == ".config" ]] && continue
      [[ `basename $item` == ".claude" ]] && continue
      [[ `basename $item` == ".local" ]] && continue
      echo "Processing $item ..."
      #  ホームディレクトリに既存のシンボリックリンクがあれば削除
      if [[ -L "$HOME/`basename $item`" ]];then
        command rm -f "$HOME/`basename $item`"
      fi
      # ホームディレクトリに同名のファイル・ディレクトリが存在する場合はバックアップディレクトリに移動
      if [[ -e "$HOME/`basename $item`" ]];then
        command mv "$HOME/`basename $item`" "$HOME/.dotbackup"
      fi
      # シンボリックリンクをホームディレクトリに作成
      command ln -snf "$item" $HOME
    done
  else
    command echo "same install src dest"
  fi
}

link_local_bin() {
  mkdir -p "$HOME/.local/bin"

  if [ -d "$SCRIPT_DIR/.local/bin" ]; then
    for item in "$SCRIPT_DIR/.local/bin/"*; do
      [ -e "$item" ] || continue
      local item_name
      item_name=$(basename "$item")
      echo "Processing .local/bin/$item_name ..."

      if [[ -L "$HOME/.local/bin/$item_name" ]]; then
        command rm -f "$HOME/.local/bin/$item_name"
      elif [[ -e "$HOME/.local/bin/$item_name" ]]; then
        command mv "$HOME/.local/bin/$item_name" "$HOME/.dotbackup/"
      fi

      command ln -snf "$item" "$HOME/.local/bin/$item_name"
    done
  fi
}

link_claude_files() {
  local claude_src="$SCRIPT_DIR/claude"
  local claude_dest="$HOME/.claude"

  if [ ! -d "$claude_src" ]; then
    return
  fi

  mkdir -p "$claude_dest"

  for item in "$claude_src"/*; do
    [ -e "$item" ] || continue
    local item_name
    item_name=$(basename "$item")
    echo "Processing claude/$item_name ..."

    if [[ -L "$claude_dest/$item_name" ]]; then
      command rm -f "$claude_dest/$item_name"
    elif [[ -e "$claude_dest/$item_name" ]]; then
      command mv "$claude_dest/$item_name" "$HOME/.dotbackup/"
    fi

    command ln -snf "$item" "$claude_dest/$item_name"
  done
}

link_config_directories() {
  # ~/.config ディレクトリが存在しない場合は作成
  if [ ! -d "$HOME/.config" ]; then
    command mkdir -p "$HOME/.config"
  fi

  # .config 内のサブディレクトリを個別にリンク
  if [ -d "$SCRIPT_DIR/.config" ]; then
    for item in $SCRIPT_DIR/.config/*; do
      if [ -e "$item" ]; then
        local item_name=`basename $item`
        echo "Processing .config/$item_name ..."

        # 既存のシンボリックリンクがあれば削除
        if [[ -L "$HOME/.config/$item_name" ]]; then
          command rm -f "$HOME/.config/$item_name"
        fi

        # 既存のファイル・ディレクトリがある場合はバックアップ
        if [[ -e "$HOME/.config/$item_name" ]]; then
          command mkdir -p "$HOME/.dotbackup/.config"
          command mv "$HOME/.config/$item_name" "$HOME/.dotbackup/.config/"
        fi

        # シンボリックリンクを作成
        command ln -snf "$item" "$HOME/.config/$item_name"
      fi
    done
  fi
}

# $#：スクリプトまたは関数に渡されたコマンドライン引数の個数を表す特殊変数
# -gt：数値比較演算子で「greater than」（より大きい）を意味
# つまり、引数が与えられた場合にそのすべてを処理するためのループ
# この構文は多くのシェルスクリプトで標準的に使われており、特にツールやユーティリティスクリプトでオプション解析を行う際の定番パターン
while [ $# -gt 0 ];do
  case ${1} in
    --debug|-d)
      set -uex
      ;;
    --help|-h)
      helpmsg
      #  スクリプトの実行を異常終了
      exit 1
      ;;
    *)
      echo "エラー: 不明なオプション '$1'" >&2
      ;;
  esac
  # shift：引数を一つずつ左にシフト
  shift
done

update_git() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "Updating git to latest version via git-core PPA..."
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt-get update -q
    sudo apt-get install -y git
  elif command -v brew >/dev/null 2>&1; then
    echo "Updating git to latest version via Homebrew..."
    brew install git || brew upgrade git
  else
    echo "No supported package manager found. Skipping git update."
    return
  fi

  echo "git updated: $(git --version)"
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    echo "mise is already installed: $(mise --version)"
    return
  fi

  echo "Installing mise..."
  if command -v curl >/dev/null 2>&1; then
    curl https://mise.run | sh || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- https://mise.run | sh || return 1
  else
    echo "Neither curl nor wget is available. Please install one of them and rerun install.sh." >&2
    return 1
  fi

  # Verify mise was installed to ~/.local/bin/mise
  if [ ! -f "$HOME/.local/bin/mise" ]; then
    echo "mise installation failed - $HOME/.local/bin/mise was not created." >&2
    return 1
  fi

  # mise activation requires shell re-sourcing; just verify file exists
  echo "mise installed successfully to $HOME/.local/bin/mise"
}

install_claude_code() {
  if command -v claude >/dev/null 2>&1; then
    echo "Claude Code is already installed: $(claude --version)"
    return
  fi

  echo "Installing Claude Code..."
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      # Windows (Git Bash / MSYS / Cygwin 経由)
      echo "Detected Windows. Installing via PowerShell..."
      powershell.exe -NoProfile -Command "irm https://claude.ai/install.ps1 | iex" || return 1
      ;;
    *)
      # macOS / Linux (WSL含む)
      echo "Detected macOS/Linux. Installing via curl..."
      curl -fsSL https://claude.ai/install.sh | bash || return 1
      ;;
  esac

  echo "Claude Code installed successfully"
}

update_git
install_mise
install_claude_code
link_to_homedir
link_config_directories
link_local_bin
link_claude_files

# Gitの設定を実行元の環境でも共有
# git config --global include.path "~/.gitconfig_shared"

# VSCode拡張機能のインストール
if command -v code &> /dev/null; then
  echo "Installing VSCode extensions..."
  bash "$SCRIPT_DIR/install-vscode-extensions.sh"
fi

# 太字のシアン色で Install completed!!!! を表示
printf "\033[1;36m Install completed!!!! \033[0m\n"

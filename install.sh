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

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew is already installed: $(brew --version | head -n1)"
    return
  fi

  case "$(uname -s)" in
    Darwin*)
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
      ;;
    *)
      echo "Homebrew install is only supported on macOS in this script. Skipping."
      return
      ;;
  esac

  echo "Homebrew installed successfully"
}

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

install_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    echo "pnpm is already installed: $(pnpm --version)"
    return
  fi

  echo "Installing pnpm..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://get.pnpm.io/install.sh | sh - || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- https://get.pnpm.io/install.sh | sh - || return 1
  else
    echo "Neither curl nor wget is available. Please install one of them and rerun install.sh." >&2
    return 1
  fi

  echo "pnpm installed successfully"
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

install_aws_cli() {
  if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI is already installed: $(aws --version)"
    return
  fi

  echo "Installing AWS CLI..."
  case "$(uname -s)" in
    Darwin*)
      # macOS
      echo "Detected macOS. Installing via pkg installer..."
      local tmp_dir
      tmp_dir="$(mktemp -d)"
      local tmp_pkg="$tmp_dir/AWSCLIV2.pkg"
      curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "$tmp_pkg" || return 1
      sudo installer -pkg "$tmp_pkg" -target / || return 1
      rm -rf "$tmp_dir"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows (Git Bash / MSYS / Cygwin 経由)
      echo "Detected Windows. Installing via PowerShell..."
      powershell.exe -NoProfile -Command "Start-Process msiexec.exe -ArgumentList '/i https://awscli.amazonaws.com/AWSCLIV2.msi /qn' -Wait" || return 1
      ;;
    *)
      # Linux (WSL含む)
      echo "Detected Linux. Installing via zip installer..."
      local tmp_dir
      tmp_dir="$(mktemp -d)"
      local arch
      arch="$(uname -m)"
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "$tmp_dir/awscliv2.zip" || return 1
      unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir" || return 1
      sudo "$tmp_dir/aws/install" || return 1
      rm -rf "$tmp_dir"
      ;;
  esac

  echo "AWS CLI installed successfully"
}

install_github_cli() {
  if command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI is already installed: $(gh --version | head -n1)"
    return
  fi

  echo "Installing GitHub CLI..."
  case "$(uname -s)" in
    Darwin*)
      # macOS
      echo "Detected macOS. Installing via pkg installer..."
      local tmp_dir
      tmp_dir="$(mktemp -d)"
      local tmp_pkg="$tmp_dir/gh.pkg"
      local pkg_url
      pkg_url="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep -o 'https://[^"]*\.pkg' | head -n1)"
      if [ -z "$pkg_url" ]; then
        echo "Could not determine latest GitHub CLI pkg URL." >&2
        rm -rf "$tmp_dir"
        return 1
      fi
      curl -fsSL "$pkg_url" -o "$tmp_pkg" || return 1
      sudo installer -pkg "$tmp_pkg" -target / || return 1
      rm -rf "$tmp_dir"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows (Git Bash / MSYS / Cygwin 経由)
      echo "Detected Windows. Installing via winget..."
      powershell.exe -NoProfile -Command "winget install --id GitHub.cli -e --source winget" || return 1
      ;;
    *)
      # Linux (WSL含む)
      if command -v apt-get >/dev/null 2>&1; then
        echo "Detected Linux (apt). Installing via official apt repository..."
        (type -p wget >/dev/null || sudo apt-get install -y wget) \
          && sudo mkdir -p -m 755 /etc/apt/keyrings \
          && wget -nv -O- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
          && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
          && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages/deb stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
          && sudo apt-get update -q \
          && sudo apt-get install -y gh || return 1
      else
        echo "Detected Linux. Installing via tarball..."
        local tmp_dir
        tmp_dir="$(mktemp -d)"
        local arch
        case "$(uname -m)" in
          x86_64) arch="amd64" ;;
          aarch64|arm64) arch="arm64" ;;
          *) echo "Unsupported architecture: $(uname -m)" >&2; return 1 ;;
        esac
        local latest_url
        latest_url="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep -o "https://.*linux_${arch}\.tar\.gz" | head -n1)"
        if [ -z "$latest_url" ]; then
          echo "Could not determine latest GitHub CLI release URL." >&2
          return 1
        fi
        curl -fsSL "$latest_url" -o "$tmp_dir/gh.tar.gz" || return 1
        tar -xzf "$tmp_dir/gh.tar.gz" -C "$tmp_dir" || return 1
        sudo install "$tmp_dir"/gh_*/bin/gh /usr/local/bin/gh || return 1
        rm -rf "$tmp_dir"
      fi
      ;;
  esac

  echo "GitHub CLI installed successfully"
}

install_gcloud_cli() {
  if command -v gcloud >/dev/null 2>&1; then
    echo "Google Cloud SDK is already installed: $(gcloud --version | head -n1)"
    return
  fi

  echo "Installing Google Cloud SDK..."
  case "$(uname -s)" in
    Darwin*)
      # macOS
      if command -v brew >/dev/null 2>&1; then
        echo "Detected macOS. Installing via Homebrew..."
        brew install --cask google-cloud-sdk || return 1
      else
        echo "Homebrew not found. Skipping Google Cloud SDK installation." >&2
        return 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows (Git Bash / MSYS / Cygwin 経由)
      echo "Detected Windows. Installing via winget..."
      powershell.exe -NoProfile -Command "winget install --id Google.CloudSDK -e --source winget" || return 1
      ;;
    *)
      # Linux (WSL含む)
      if command -v apt-get >/dev/null 2>&1; then
        echo "Detected Linux (apt). Installing via official apt repository..."
        sudo apt-get install -y apt-transport-https ca-certificates gnupg curl \
          && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
          && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null \
          && sudo apt-get update -q \
          && sudo apt-get install -y google-cloud-cli || return 1
      else
        echo "Detected Linux. Installing via official install script..."
        curl -fsSL https://sdk.cloud.google.com | bash || return 1
      fi
      ;;
  esac

  echo "Google Cloud SDK installed successfully"
}

install_1password_cli() {
  if command -v op >/dev/null 2>&1; then
    echo "1Password CLI is already installed: $(op --version)"
    return
  fi

  echo "Installing 1Password CLI..."
  case "$(uname -s)" in
    Darwin*)
      # macOS
      if command -v brew >/dev/null 2>&1; then
        echo "Detected macOS. Installing via Homebrew..."
        brew install --cask 1password-cli || return 1
      else
        echo "Homebrew not found. Skipping 1Password CLI installation." >&2
        return 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows (Git Bash / MSYS / Cygwin 経由)
      echo "Detected Windows. Installing via winget..."
      powershell.exe -NoProfile -Command "winget install --id AgileBits.1Password.CLI -e --source winget" || return 1
      ;;
    *)
      # Linux (WSL含む)
      if command -v apt-get >/dev/null 2>&1; then
        echo "Detected Linux (apt). Installing via official apt repository..."
        local arch
        case "$(uname -m)" in
          x86_64) arch="amd64" ;;
          aarch64|arm64) arch="arm64" ;;
          *) echo "Unsupported architecture: $(uname -m)" >&2; return 1 ;;
        esac
        sudo mkdir -p /usr/share/keyrings \
          && curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg \
          && echo "deb [arch=${arch} signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/${arch} stable main" | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null \
          && sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ \
          && curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null \
          && sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 \
          && curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg \
          && sudo apt-get update -q \
          && sudo apt-get install -y 1password-cli || return 1
      else
        echo "No supported package manager found. Skipping 1Password CLI installation." >&2
        return 1
      fi
      ;;
  esac

  echo "1Password CLI installed successfully"
}

install_homebrew
update_git
install_1password_cli
install_mise
install_pnpm
install_claude_code
install_aws_cli
install_github_cli
install_gcloud_cli
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

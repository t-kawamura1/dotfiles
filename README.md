# dotfiles

個人的な設定ファイル（dotfiles）を管理するリポジトリです。Bash/Zsh環境での開発効率を向上させる設定とスクリプトを含んでいます。

## 📋 概要

このdotfilesリポジトリは以下の機能を提供します：

- **安全なファイル操作**: `rm`、`mv`、`cp`コマンドに確認オプションを自動追加
- **カスタムスクリプト管理**: `.local/bin`ディレクトリ内のスクリプトをシステム全体で利用可能に
- **VSCode拡張機能の自動インストール**: 開発に必要な拡張機能を一括インストール
- **シェル環境の最適化**: 履歴管理、プロンプト設定、補完機能の強化
- **ツールバージョン管理**: miseによる開発ツールのバージョン管理設定

## 📁 ファイル構成

```
.
├── .aliases                      # 共通エイリアス定義
├── .bashrc                       # Bash設定ファイル
├── .gitignore                    # Gitの追跡除外設定
├── .npmrc                        # npm設定ファイル
├── .zshrc                        # Zsh設定ファイル
├── .config/                      # アプリケーション設定ディレクトリ
│   ├── git/                      # Git設定（XDGパス）
│   │   ├── config                # Git設定ファイル（~/.gitconfig相当）
│   │   ├── ignore                # グローバルgitignore（~/.gitignore相当）
│   │   └── hooks/
│   │       └── pre-commit        # pre-commitフック（actionlint/zizmor/gitleaks）
│   └── mise/                     # mise設定
│       └── config.toml           # miseグローバル設定（actionlint/zizmor/gitleaks/node/pnpm）
├── .local/
│   └── bin/                      # カスタムスクリプト格納ディレクトリ
│       └── mkfile                # ファイル作成スクリプト（例）
├── .vscode/
│   └── settings.json             # VSCode設定ファイル
├── claude/                       # Claude Code設定
│   ├── CLAUDE.md
│   └── settings.json
├── install.sh                    # dotfilesインストールスクリプト
├── install-vscode-extensions.sh  # VSCode拡張機能インストールスクリプト
└── README.md                     # このファイル
```

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/t-kawamura1/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. dotfilesのインストール

```bash
./install.sh
```

このスクリプトは以下を実行します：

- 環境に応じてGitを最新化（apt / Homebrew）
- `mise` が未インストールの場合は自動インストール
- 既存のdotfilesを `~/.dotbackup` にバックアップ
- dotfilesをホームディレクトリにシンボリックリンクとして配置
  - `.config/` 配下は `~/.config/` 配下にサブディレクトリ単位でリンク
  - `.local/bin/` 配下は `~/.local/bin/` 配下にファイル単位でリンク
  - `claude/` 配下は `~/.claude/` 配下にリンク
- VSCodeがインストールされている場合、自動的に拡張機能をインストール

### 3. 設定の反映

```bash
# zshの場合
source ~/.zshrc
# または
exec zsh

# bashの場合
source ~/.bashrc
# または
exec bash
```

## 🔧 トラブルシューティング

### インストールオプション

```bash
# デバッグモードで実行
./install.sh --debug

# ヘルプを表示
./install.sh --help
```

### バックアップからの復元

```bash
# バックアップディレクトリから復元
cp ~/.dotbackup/.bashrc ~/
```

### 設定の確認

```bash
# 現在のエイリアス一覧を確認
alias

# 特定のエイリアスを確認
alias | grep rm
```

## 🔄 更新手順

```bash
cd ~/dotfiles
git pull origin main
./install.sh
source ~/.zshrc  # bashの場合は source ~/.bashrc
```

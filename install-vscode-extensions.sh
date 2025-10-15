#!/usr/bin/env bash

# インストールする拡張機能のリスト
extensions=(
  "dbaeumer.vscode-eslint"
  "esbenp.prettier-vscode"
  "Anthropic.claude-code"
  "donjayamanne.githistory"
  "mhutchie.git-graph"
  "eamodio.gitlens"
  "GitHub.copilot"
  "ms-vscode-remote.vscode-remote-extensionpack"
  "formulahendry.auto-rename-tag"
  "vincaslt.highlight-matching-tag"
  "PKief.material-icon-theme"
  "SimonSiefke.svg-preview"
  "wayou.vscode-todo-highlight"
  "yzhang.markdown-all-in-one"
  "yzane.markdown-pdf"
  "bierner.markdown-mermaid"
  "bmewburn.vscode-intelephense-client"
  "bradlc.vscode-tailwindcss"
  "shardulm94.trailing-spaces"
  "vitest.explorer"
  "astro-build.astro-vscode"
  "AmazonWebServices.aws-toolkit-vscode"
)

# 拡張機能をインストール
for extension in "${extensions[@]}"; do
  code --install-extension "$extension" --force
done

echo "VSCode extensions installed successfully!"
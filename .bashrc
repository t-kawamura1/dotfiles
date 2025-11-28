# ~/.bashrc: 非ログインシェル用にbash(1)によって実行されます。
# 例については /usr/share/doc/bash/examples/startup-files (bash-docパッケージ内)
# を参照してください

# 対話的に実行されていない場合は何もしない
case $- in
    *i*) ;;
      *) return;;
esac

# 履歴に重複行やスペースで始まる行を記録しない。
# その他のオプションについてはbash(1)を参照
# 目的: 同じコマンドの重複や、パスワード入力などの機密コマンドを履歴に残さないセキュリティ機能
HISTCONTROL=ignoreboth

# 履歴ファイルに追記する（上書きしない）
# 目的: 複数のターミナルセッション使用時、すべてのセッションの履歴を保持
shopt -s histappend

# 履歴の長さの設定についてはbash(1)のHISTSIZEとHISTFILESIZEを参照
# 目的: メモリ内履歴とファイル保存履歴の最大行数を設定し、メモリ使用量とディスク容量のバランスを取る
HISTSIZE=1000
HISTFILESIZE=2000

# 各コマンド後にウィンドウサイズをチェックし、必要に応じて
# LINESとCOLUMNSの値を更新する。
# 目的: ターミナルサイズ変更時に環境変数を自動更新し、アプリケーションが正しい画面サイズを認識
shopt -s checkwinsize

# cdのスペルミス自動修正
shopt -s cdspell

# 設定されている場合、パス名展開コンテキストで使用される "**" パターンは
# すべてのファイルと0個以上のディレクトリとサブディレクトリにマッチします。
# 目的: **パターンでサブディレクトリを再帰的に検索可能にする（例: **/*.txt）
#shopt -s globstar

# lessをテキスト以外の入力ファイルに対してより使いやすくする、lesspipe(1)を参照
# 目的: lessコマンドでzipファイルや画像ファイルなどの内容も表示できるようにする前処理機能
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# 作業中のchrootを識別する変数を設定（以下のプロンプトで使用）
# 目的: Dockerコンテナやchroot環境内での作業時、プロンプトに環境名を表示して識別しやすくする
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# 装飾されたプロンプトを設定（色が「欲しい」とわかっている場合を除き、無色）
# 目的: ターミナルが色をサポートしている場合のみ色付きプロンプトを有効化し、互換性を保つ
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# ターミナルが機能を持っている場合は色付きプロンプトのコメントを解除する；
# ユーザーの注意をそらさないためにデフォルトでオフになっている：
# ターミナルウィンドウでの焦点はプロンプトではなくコマンドの出力にあるべき
# 目的: 強制的に色付きプロンプトを有効にするオプション（ユーザーが意図的に有効化する必要がある）
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # 色のサポートがあります；Ecma-48に準拠していると仮定
        # (ISO/IEC-6429)。（そのようなサポートの欠如は極めて稀で、
        # そのような場合はsetafではなくsetfをサポートする傾向があります。）
        # 目的: 色制御の技術的背景説明（現代のターミナルはほぼ全てEcma-48標準をサポート）
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u:\w\$ '
fi
unset color_prompt force_color_prompt

# これがxtermの場合、タイトルをuser@host:dirに設定
# 目的: xtermやrxvt系ターミナルのウィンドウタイトルバーに現在の状況を表示し、複数ターミナル使用時の識別に活用
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# dircolorsユーティリティが利用可能で実行可能かチェック
# ~/.dircolorsファイルが存在し読み取り可能な場合は、それを使用してLS_COLORS環境変数を設定
# そうでない場合は、システムデフォルトのdircolors設定を使用
# これにより、lsコマンドの出力やその他のディレクトリ一覧ツールの色設定を構成
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# 色付きGCCの警告とエラー
# 目的: GCCコンパイラの出力で警告やエラーを色分けして見やすくする
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# 長時間実行されるコマンド用の "alert" エイリアスを追加。次のように使用：
#   sleep 10; alert
# 目的: 長時間実行されるコマンド完了時にデスクトップ通知を表示
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# 共通エイリアスファイルを読み込み（dotfiles管理）
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

# プログラマブル補完機能を有効にする（既に/etc/bash.bashrcで有効になっており、
# /etc/profileが/etc/bash.bashrcをソースしている場合は、これを有効にする必要はありません）。
# 目的: タブキーでのコマンドやファイル名の自動補完機能を有効化し、入力効率を向上
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
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

# NVM (Node Version Manager) の設定
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # nvmを読み込み
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # nvmのbash補完を読み込み
# 目的: Node Version Manager(NVM)の初期化とコマンド補完機能を有効化
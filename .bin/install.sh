# !/usr/bin/env bash

# エラーを検出し、スクリプトの実行を停止する
set -ueo pipefail

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

  # "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)" はスクリプトのディレクトリを取得するためのコマンド
  # dirname "${BASH_SOURCE[0]}" はスクリプトのパスからディレクトリ部分を取得し、
  # cd コマンドでそのディレクトリに移動し、pwd -P で絶対パスを取得
  # この方法は、スクリプトがどのディレクトリから実行されても、正しいパスを取得するために使用される
  # pwd -P はシンボリックリンクを解決して、実際のパスを取得
  # これにより、スクリプトがどのディレクトリから実行されても、正しいパスを取得できる
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

  # dirname コマンドを使用して、スクリプトのディレクトリの親ディレクトリを取得
  local dotdir=$(dirname ${script_dir})
  
  # dotdir がホームディレクトリと異なる場合のみ、シンボリックリンクを作成
  # これは同じディレクトリ内でシンボリックリンクを作成してしまう事故を防ぐため
  if [[ "$HOME" != "$dotdir" ]];then
    # /.??* ドットで始まる（ドットを含めた）3文字以上のファイル名・ディレクリ名にマッチ
    for file in $dotdir/.??*; do
      # .git ディレクトリはスキップ
      [[ `basename $file` == ".git" ]] && continue
      #  ホームディレクトリに既存のシンボリックリンクがあれば削除
      if [[ -L "$HOME/`basename $file`" ]];then
        command rm -f "$HOME/`basename $file`"
      fi
      # ホームディレクトリに同名のファイル・ディレクトリが存在する場合はバックアップディレクトリに移動
      if [[ -e "$HOME/`basename $file`" ]];then
        command mv "$HOME/`basename $file`" "$HOME/.dotbackup"
      fi
      # シンボリックリンクをホームディレクトリに作成
      command ln -snf $file $HOME
    done
  else
    command echo "same install src dest"
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

link_to_homedir

# Gitの設定を実行元の環境でも共有
# git config --global include.path "~/.gitconfig_shared"

# 太字のシアン色で Install completed!!!! を表示
command echo -e "\e[1;36m Install completed!!!! \e[m"

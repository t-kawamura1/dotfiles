# ghalint の出力を整形するスクリプト
# ghalint run の構造化ログからジョブ名・アクション名・エラー内容を抽出し、
# 1行ずつ見やすく整形して出力する。エラーメッセージは赤字で表示。
#
# 使い方:
#   ghalint run 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | gawk -f ghalint-fmt.awk
# または ~/.bashrc / ~/.zshrc に登録したエイリアス:
#   ghalint-fmt
{
  match($0, /job_name=([^ ]+)/, j)
  match($0, /action=([^ ]+)/, a)
  match($0, /error="([^"]+)"/, e)
  if (j[1] != "") printf "job=%-15s action=%-20s \033[31m%s\033[0m\n", j[1], a[1], e[1]
}

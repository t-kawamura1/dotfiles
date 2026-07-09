# mise の shims を全てのzsh起動(non-interactive含む)でPATHに通す
# 理由: .zshrc の `mise activate zsh` はinteractiveシェルでしか読まれず、
# ツール等のnon-interactiveシェルからだとnode/npm/npxが見つからないため
export PATH="$HOME/.local/share/mise/shims:$PATH"

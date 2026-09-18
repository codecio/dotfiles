# Setup fzf
# ---------
# HOMEBREW_PREFIX comes from brew shellenv in ~/.zprofile.
if [[ -n ${HOMEBREW_PREFIX:-} && ! "$PATH" == *$HOMEBREW_PREFIX/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}$HOMEBREW_PREFIX/opt/fzf/bin"
fi

# Auto-completion
# ---------------
if [[ $- == *i* && -n ${HOMEBREW_PREFIX:-} && -f $HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh ]]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
fi

# Key bindings
# ------------
if [[ -n ${HOMEBREW_PREFIX:-} && -f $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh ]]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
fi

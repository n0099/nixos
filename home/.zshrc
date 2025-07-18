# https://superuser.com/questions/410965/command-history-in-zsh
setopt INC_APPEND_HISTORY

# https://github.com/zsh-users/zsh-autosuggestions/blob/85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5/README.md#suggestion-strategy
ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion)

# https://github.com/ohmyzsh/ohmyzsh/tree/3e7ef0182f59c7990a52cf6ec2981adb56d5b368/plugins/alias-finder
zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' cheaper yes

# https://github.com/ohmyzsh/ohmyzsh/tree/3e7ef0182f59c7990a52cf6ec2981adb56d5b368/plugins/docker
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# https://github.com/zsh-users/zsh-autosuggestions/issues/238#issuecomment-389324292
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

alias cat="bat -p --theme=ansi"
alias ls='eza --group-directories-first --icons --hyperlink'
alias ll='ls --long --header'
alias l=ls
alias rm=trash

# Abbreviations
abbr --add vi nvim

# Source machine-specific aliases
if test -f ~/.extra_aliases.fish
    source ~/.extra_aliases.fish
end

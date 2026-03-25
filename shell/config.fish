# Env vars
set -gx VISUAL nvim
set -gx EDITOR nvim
set -gx LESS '-R'
set -gx BAT_PAGER 'less -R'
set -gx PAGER 'bat --paging=always'
fish_add_path $HOME/.local/bin $HOME/local/bin

# Integrations
if test "$CLAUDECODE" != "1"
    starship init fish | source
    fzf --fish | source
    zoxide init --cmd cd fish | source
end

# Aliases
source ~/.aliases.fish

# Homebrew (macOS)
if test -f /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end

# Env vars
set -gx VISUAL nvim
set -gx EDITOR nvim
set -gx LESS '-R'
set -gx BAT_PAGER 'less -R'
set -gx PAGER 'bat --paging=always'
fish_add_path $HOME/.local/bin $HOME/local/bin

# Upgrade bare xterm to 256color over SSH so tmux/catppuccin get true color
if test "$TERM" = "xterm"; and set -q SSH_CONNECTION
    set -gx TERM xterm-256color
end

# Integrations
if test "$CLAUDECODE" != "1"
    starship init fish | source
    fzf --fish | source
    zoxide init --cmd cd fish | source
end

# Aliases
source ~/.aliases.fish

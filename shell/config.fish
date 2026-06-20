# Env vars
set -gx VISUAL nvim
set -gx EDITOR nvim

# Upgrade bare xterm to 256color over SSH so tmux/catppuccin get true color
if test "$TERM" = "xterm"; and set -q SSH_CONNECTION
    set -gx TERM xterm-256color
end

# Integrations
starship init fish | source
fzf --fish | source
zoxide init --cmd cd fish | source

# Aliases
source ~/.aliases.fish

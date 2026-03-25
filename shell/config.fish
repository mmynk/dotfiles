# Env vars
set -gx VISUAL nvim
set -gx EDITOR nvim

# Integrations
starship init fish | source
fzf --fish | source
zoxide init --cmd cd fish | source

# Aliases
source ~/.aliases.fish

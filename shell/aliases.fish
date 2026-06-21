alias cat="bat -p --theme=ansi"
alias ls='eza --group-directories-first --icons --hyperlink'
alias ll='ls --long --header'
alias l=ls
alias rm=trash

# Abbreviations
abbr --add vi nvim

# nix helpers
function nix_update
    pushd ~/.config/nix
    nix flake update && echo "nix flake update done..."
    popd
end

alias nix_gc='nix store gc && echo "nix store gc done..."'

function nix_install
    if test (uname) = Darwin
        sudo darwin-rebuild switch --flake ~/.config/nix#$USER
        echo "nix darwin-rebuild done..."
    else
        nix run nixpkgs#home-manager -- switch --flake ~/.config/nix
        echo "nix home-manager rebuild done..."
    end
end

function nix_rebuild
    nix_update && nix_gc
    nix_install
end

# Source machine-specific aliases
if test -f ~/.extra_aliases.fish
    source ~/.extra_aliases.fish
end

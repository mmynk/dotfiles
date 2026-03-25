function nix_update
    pushd ~/.config/nix
    nix flake update && echo "nix flake update done..."
    popd
end

alias nix_gc='nix store gc && echo "nix store gc done..."'

function nix_install
    sudo darwin-rebuild switch --flake ~/.config/nix#$USER
    echo "nix darwin-rebuild done..."
end

function nix_rebuild
    nix_update && nix_gc
    nix_install
end

alias bat=cat
alias cat="batcat -p --theme=ansi"
alias v=nvim

nix_update() {
  cd ~/.config/nix
  nix flake update && echo "nix flake update done..."
  nix store gc && echo "nix store gc done..."
  cd -
}

nix_rebuild() {
  nix run nixpkgs#home-manager -- switch --flake ~/.config/nix
  echo "nix home-manager rebuild done..."
}

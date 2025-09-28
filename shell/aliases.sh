alias bat=cat
alias cat="batcat -p --theme=ansi"
alias vi=nvim

nix_update() {
  cd ~/.config/nix
  nix flake update && echo "nix flake update done..."
  nix store gc && echo "nix store gc done..."
  cd -
}

nix_rebuild() {
  # For Linux
  # nix run nixpkgs#home-manager -- switch --flake ~/.config/nix
  # echo "nix home-manager rebuild done..."

  # For macOS
  sudo darwin-rebuild switch --flake ~/.config/nix#${USER}
  echo "nix darwin-rebuild done..."
}

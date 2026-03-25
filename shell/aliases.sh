alias cat="bat -p --theme=ansi"
alias vi=nvim
alias s='kitten ssh'
alias ls='eza --group-directories-first --icons --hyperlink'
alias ll='ls --long --header'
alias l=ls
alias rm='trash'

nix_update() {
  cd ~/.config/nix
  nix flake update && echo "nix flake update done..."
}

alias nix_gc='nix store gc && echo "nix store gc done..."'

nix_install() {
  # For Linux
  # nix run nixpkgs#home-manager -- switch --flake ~/.config/nix
  # echo "nix home-manager rebuild done..."

  # For macOS
  sudo darwin-rebuild switch --flake ~/.config/nix#${USER}
  echo "nix darwin-rebuild done..."
}

nix_rebuild() {
  nix_update && nix_gc
  nix_install
}

[[ -f ~/.extra_aliases ]] && source ~/.extra_aliases

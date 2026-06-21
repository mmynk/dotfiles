{ config, pkgs, ... }:

{
  home.username = "<username>";
  home.homeDirectory = "/home/<username>";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    bat
    below
    eza
    fd
    fish
    fzf
    gh
    glow
    less
    mosh
    neovim
    ripgrep
    starship
    tmux
    trash-cli
    tree
    zoxide
  ];

  # Dotfile symlinks (config.fish, aliases.fish, starship.toml, etc.) are owned
  # by the install script's setup_fish/setup_common on BOTH linux and mac — see
  # ./install. home-manager here only installs packages, so it does not fight the
  # install script over the same target files. (Having both manage them caused
  # "Conflicting managed target files" / clobber errors.)
  programs.home-manager.enable = true;
}

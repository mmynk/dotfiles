{ config, pkgs, ... }:

{
  home.username = "<username>";
  home.homeDirectory = "/home/<username>";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    bat
    eza
    fd
    fzf
    glow
    less
    mosh
    neovim
    ripgrep
    starship
    trash-cli
    tree
    zoxide
  ];

  programs.fish.enable = true;

  home.file.".config/fish/config.fish" = {
    source = config.lib.file.mkOutOfStoreSymlink <pwd>/shell/config.fish;
  };

  home.file.".aliases.fish" = {
    source = config.lib.file.mkOutOfStoreSymlink <pwd>/shell/aliases.fish;
  };

  home.file.".config/starship.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink <pwd>/config/starship.toml;
  };

  programs.home-manager.enable = true;
}

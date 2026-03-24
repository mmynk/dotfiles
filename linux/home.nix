{ config, pkgs, ... }:

{
  home.username = "<username>";
  home.homeDirectory = "/home/<username>";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    bat
    eza
    fd
    fish
    fzf
    less
    mosh
    neovim
    ripgrep
    starship
    trash-cli
    zoxide
  ];

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

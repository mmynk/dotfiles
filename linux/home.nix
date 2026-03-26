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

  programs.home-manager.enable = true;
}

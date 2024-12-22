{ config, pkgs, ... }:

{
  home.username = "<username>";
  home.homeDirectory = "/home/<username>";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    bat
    fzf
    gh
    go
    oh-my-zsh
    python3
    zoxide
    zsh
  ];

  home.file.".zshrc" = {
    source = config.lib.file.mkOutOfStoreSymlink /home/mmayank/dev/dotfiles/shell/zshrc;
  };

  home.file.".aliases" = {
    source = config.lib.file.mkOutOfStoreSymlink /home/mmayank/dev/dotfiles/shell/aliases.sh;
  };

  home.file.".oh-my-zsh/themes/custom-rr.zsh-theme" = {
    source = config.lib.file.mkOutOfStoreSymlink /home/mmayank/dev/dotfiles/shell/custom-rr.zsh-theme;
  };

  home.file.".vimrc" = {
    source = config.lib.file.mkOutOfStoreSymlink /home/mmayank/dev/dotfiles/apps/vimrc;
  };

  programs.git = {
    enable = true;
    userName = "mmynk";
    userEmail = "mohit.ritanil@gmail.com";
  };

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      LazyVim
    ];
  };

  programs.home-manager.enable = true;
}

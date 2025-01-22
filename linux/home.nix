{ config, pkgs, ... }:

{
  home.username = "<username>";
  home.homeDirectory = "/home/<username>";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    bat
    fzf
    git
    gitAndTools.gh
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

  home.file.".avx" = {
    source = config.lib.file.mkOutOfStoreSymlink /home/mmayank/dev/dotfiles/shell/avx.sh;
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

    extraConfig = {
      credential = {
        helper = "${pkgs.gitAndTools.gh}/bin/gh auth git-credential";
      };
    };
  };

  programs.gh = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      LazyVim
    ];
  };

  programs.home-manager.enable = true;
}

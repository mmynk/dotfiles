{
  description = "BatBook nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
        bat
        eza
        fd
        fzf
        glow
        less
        neovim
        python3
        ripgrep
        starship
        tmux
        trash-cli
        tree
        zoxide
      ];

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;
      users.users."<username>".shell = pkgs.fish;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # Daily auto-update: update flake inputs, rebuild, and gc
      launchd.daemons.nix-auto-update = {
        script = ''
          export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH
          OWNER=$(stat -f '%Su' /dev/console)
          FLAKE_DIR="/Users/$OWNER/.config/nix"
          cd "$FLAKE_DIR"
          nix flake update 2>&1
          darwin-rebuild switch --flake ".#$OWNER" 2>&1
          nix store gc 2>&1
        '';
        serviceConfig = {
          StartCalendarInterval = [{ Hour = 3; Minute = 0; }];
          StandardOutPath = "/tmp/nix-auto-update.log";
          StandardErrorPath = "/tmp/nix-auto-update.err.log";
        };
      };

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#<username>
    darwinConfigurations."<username>" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}

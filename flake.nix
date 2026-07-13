{
  description = "Example nix-darwin system flake";

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
    environment.systemPackages =
        [ pkgs.vim
          pkgs.git
          pkgs.clang
          pkgs.uv
          pkgs.vscode
          pkgs.rustup
          pkgs.texliveFull
          pkgs.ripgrep
        ];

      # Manage Homebrew with Nix
      homebrew = {
        enable = true;
        casks = [
          "ghostty"
        ];
        vscode = [
          "ms-python.python"
          "charliermarsh.ruff"
          "tamasfe.even-better-toml"
          "ms-toolsai.jupyter"
          "James-Yu.latex-workshop"
        ];
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Allow Unfree packages
      nixpkgs.config.allowUnfree = true;

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;
      programs.zsh = {
        enable = true;
        enableSyntaxHighlighting = true;
      };

      # TMUX
      programs.tmux = {
        enable = true;
        enableSensible = true;
      };

      programs.vim = {
        enable = true;
        enableSensible = true;
        vimConfig = (builtins.readFile ./vimrc);
      };

      # Set primary user, since some configs apply to that user
      # but the rebuild command runs as root.
      system.primaryUser = "alister";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # Use TouchID for sudo
      security.pam.services.sudo_local.touchIdAuth = true;
      system.defaults.NSGlobalDomain.AppleShowAllExtensions = false;
      system.defaults.controlcenter.BatteryShowPercentage = true;
      system.defaults.dock.expose-animation-duration = 0.3;
      system.defaults.dock.mru-spaces = false;
      system.defaults.finder.FXPreferredViewStyle = "clmv";
      system.defaults.finder.ShowPathbar = true;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # using Determinate, disable nix's own management
      nix.enable = false;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."Pharloom" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
      ];
    };
  };
}

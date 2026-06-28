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
          pkgs.ghostty-bin
          pkgs.uv
          pkgs.vscode
          pkgs.rustup
        ];

      # Manage Homebrew with Nix
      homebrew = {
        enable = true;
	vscode = [
          "ms-python.python"
          "charliermarsh.ruff"
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

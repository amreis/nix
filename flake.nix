{
  description = "My Nix-Darwin config for Pharloom";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      mac-app-util,
    }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = [
          pkgs.vim
          pkgs.git
          pkgs.clang
          pkgs.uv
          pkgs.typst
          pkgs.vscode
          pkgs.rustup
          pkgs.texliveFull
          pkgs.ripgrep
          pkgs.ruby
          pkgs.libllvm # some ruby gems need `dsymutil` to compile
          pkgs.pkg-config # Critical for native gem extensions to find dependencies
          pkgs.openssl
          pkgs.openssl.dev
          pkgs.nixfmt
        ];

        # Some env vars for ruby to be able to find openssl
        environment.variables = {
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
          RUBY_CONFIGURE_OPTS = "--with-openssl-dir=${pkgs.openssl.dev}";
        };

        # Manage Homebrew with Nix
        homebrew = {
          enable = true;
          casks = [
            "ghostty"
            "visual-studio-code"
          ];
          vscode = [
            "ms-python.python"
            "charliermarsh.ruff"
            "tamasfe.even-better-toml"
            "ms-toolsai.jupyter"
            "James-Yu.latex-workshop"
            "streetsidesoftware.code-spell-checker"
            "bbenoist.Nix"
          ];

          onActivation.cleanup = "uninstall";
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
        system.defaults = {
          NSGlobalDomain = {
            AppleShowAllExtensions = false;
            InitialKeyRepeat = 10;
            ApplePressAndHoldEnabled = false;
            KeyRepeat = 2;
          };

          dock = {
            expose-animation-duration = 0.3;
            mru-spaces = false;
            autohide = true;
          };

          controlcenter.BatteryShowPercentage = true;

          finder = {
            FXPreferredViewStyle = "Nlsv";
            ShowPathbar = true;
          };

        };

        users.users.alister = {
          name = "alister";
          home = "/Users/alister";
        };

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        # using Determinate, disable nix's own management
        nix.enable = false;
      };
      homeconfig = { pkgs, ... }: {
        # From https://davi.sh/blog/2024/02/nix-home-manager/

        # Shouldn't be changed!!!
        home.stateVersion = "26.05";

        # Let home-manager install and manage itself
        programs.home-manager.enable = true;

        home.packages = with pkgs; [ ];

        home.sessionVariables = {
          EDITOR = "vim";
        };

        home.file.".vimrc".source = ./vimrc;

        programs.zsh = {
          enable = true;
          shellAliases = {
            switch = "sudo darwin-rebuild switch --flake ~/nix-darwin-config";
          };
        };

        programs.git = {
          enable = true;
          settings = {
            user.name = "Alister Machado";
            user.email = "alister.reis@gmail.com";
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
          };
          ignores = [ ".DS_Store" ];
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."Pharloom" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.alister = homeconfig;
            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
            ];
          }
        ];
      };
    };
}

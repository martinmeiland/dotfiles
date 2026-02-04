{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    };

  outputs = inputs@{ self, nix-darwin, mac-app-util, nixpkgs, home-manager, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    configuration = { pkgs, config, ... }: {
      system.primaryUser = "martinmeiland";
      nixpkgs.config.allowUnfree = true;
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.neovim
          pkgs.ripgrep-all
	        pkgs.git
	        pkgs.mkalias
	        pkgs.tmux
          pkgs.oh-my-zsh
          pkgs.zsh
          pkgs.wezterm
          pkgs.thunderbird
	        pkgs.yabai
	        pkgs.python313
          pkgs.powerline-fonts
          pkgs.kew
          pkgs.hyfetch
          pkgs.openssh_hpnWithKerberos
          pkgs.pandoc
          pkgs.obsidian
          pkgs.ffmpeg
        ];

    fonts.packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];
      
    homebrew = {
	    enable = true;
	    brews = [
	      "mas"
	    ];
	    casks = [
	      "zen"
	      "1password"
	      "alfred"
	      "marta"
        "microsoft-office"
        "ukelele"
	    ];
	    masApps = {
	      "FuzzyTime" = 950297057;
	      "Amphetamine" = 937984704;
	    };

	    onActivation.cleanup = "uninstall";
	    onActivation.autoUpdate = true;
	    onActivation.upgrade = true;
    };

    system.defaults = {
	    dock.autohide = true;
	    dock.orientation = "left";
	    dock.persistent-apps = [
		    "/Applications/Zen.app"
		    "${pkgs.wezterm}/Applications/Nix Trampolines/WezTerm.app"
		    "/System/Applications/App Store.app"
		    "/System/Applications/System Settings.app"
	    ];
	    dock.persistent-others = [
	    ];
	    dock.show-recents = false;
	    finder.FXPreferredViewStyle = "clmv";
	    loginwindow.GuestEnabled = false;
    };

      # services.nix-daemon.enable = true;

      # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

    users.users = {
      martinmeiland = {
        home = "/Users/martinmeiland/";
        shell = pkgs.zsh;
      };
    };

      # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
    system.stateVersion = 6;

      # The platform the configuration will be used on.
    nixpkgs.hostPlatform = "x86_64-darwin";
  };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."macos" = nix-darwin.lib.darwinSystem {
      modules = [ 
	      configuration
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.martinmeiland = import ./home.nix;
        }
	      mac-app-util.darwinModules.default
	      nix-homebrew.darwinModules.nix-homebrew {
		      nix-homebrew = {
            		# Install Homebrew under the default prefix
            enable = true;
            
	    		# User owning the Homebrew prefix
            user = "martinmeiland";

			      taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };

			      mutableTaps = false;
		      };
	      }
	    ];
    };

   # Expose packages
   darwinPackages = self.darwinConfigurations."macos".pkgs;
  };
}
